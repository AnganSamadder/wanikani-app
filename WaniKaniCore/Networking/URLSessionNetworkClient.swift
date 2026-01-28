import Foundation

public final class URLSessionNetworkClient: NetworkClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let logger = SmartLogger(subsystem: "com.angansamadder.wanikani", category: "Networking")
    private static let maxBodyPreviewBytes = 600
    
    public init(
        baseURL: URL = URL(string: "https://api.wanikani.com/v2")!,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format: \(dateString)"
            )
        }
    }

    private func redactedHeaders(_ headers: [String: String]) -> [String: String] {
        var sanitized: [String: String] = [:]
        for (key, value) in headers {
            let lowerKey = key.lowercased()
            if lowerKey == "authorization" {
                sanitized[key] = redactAuthorization(value)
            } else if lowerKey.contains("token") || lowerKey.contains("cookie") {
                sanitized[key] = "<redacted>"
            } else {
                sanitized[key] = value
            }
        }
        return sanitized
    }

    private func redactAuthorization(_ value: String) -> String {
        let parts = value.split(separator: " ")
        guard parts.count == 2 else { return "<redacted>" }
        let scheme = parts[0]
        let token = String(parts[1])
        if token.count <= 8 {
            return "\(scheme) <redacted>"
        }
        let prefix = token.prefix(4)
        let suffix = token.suffix(4)
        return "\(scheme) \(prefix)…\(suffix)"
    }

    private func bodyPreview(_ data: Data) -> String {
        guard !data.isEmpty else { return "<empty>" }
        let previewData = data.prefix(Self.maxBodyPreviewBytes)
        let previewString = String(decoding: previewData, as: UTF8.self)
        if data.count > previewData.count {
            return "\(previewString)… (truncated, \(data.count) bytes)"
        }
        return "\(previewString) (\(data.count) bytes)"
    }
    
    public func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true) else {
            throw NetworkError.invalidURL
        }
        
        if !endpoint.queryParameters.isEmpty {
            components.queryItems = endpoint.queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        
        for (key, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        #if DEBUG
        logger.debug("➡️ [REQUEST] \(endpoint.method.rawValue) \(url.absoluteString)")
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            logger.debug("   Headers: \(redactedHeaders(headers))")
        }
        if let body = request.httpBody, !body.isEmpty {
            logger.debug("   Body: \(bodyPreview(body))")
        }
        #endif
        
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            #if DEBUG
            logger.error("❌ [ERROR] Request failed: \(error)")
            #endif
            throw NetworkError.noConnection
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(NSError(domain: "NetworkClient", code: -1))
        }
        
        #if DEBUG
        logger.debug("⬅️ [RESPONSE] \(httpResponse.statusCode) \(url.absoluteString)")
        if !data.isEmpty {
            logger.debug("   Body: \(bodyPreview(data))")
        }
        #endif
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                #if DEBUG
                print("   ❌ Decode error: \(error.localizedDescription)")
                #endif
                throw NetworkError.decodingFailed(error)
            }
        case 401:
            throw NetworkError.unauthorized
        case 429:
            // WaniKani API provides RateLimit-Reset (epoch timestamp) or Retry-After (seconds)
            let retryAfter: Int
            if let resetHeader = httpResponse.value(forHTTPHeaderField: "RateLimit-Reset"),
               let resetTimestamp = Double(resetHeader) {
                let resetDate = Date(timeIntervalSince1970: resetTimestamp)
                retryAfter = max(1, Int(resetDate.timeIntervalSinceNow))
            } else if let retryAfterHeader = httpResponse.value(forHTTPHeaderField: "Retry-After"),
                      let retryAfterValue = Int(retryAfterHeader) {
                retryAfter = retryAfterValue
            } else {
                retryAfter = 60 // Default to 60 seconds
            }
            throw NetworkError.rateLimited(retryAfter: retryAfter)
        case 500...599:
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        default:
            throw NetworkError.unknown(NSError(domain: "NetworkClient", code: httpResponse.statusCode))
        }
    }
    
}

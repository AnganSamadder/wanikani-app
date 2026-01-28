import Foundation

public final class URLSessionNetworkClient: NetworkClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    
    public init(
        baseURL: URL = URL(string: "https://api.wanikani.com/v2")!,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
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
        print("➡️ [REQUEST] \(endpoint.method.rawValue) \(url.absoluteString)")
        if let headers = request.allHTTPHeaderFields {
            print("   Headers: \(headers)")
        }
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("   Body: \(bodyString)")
        }
        #endif
        
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            #if DEBUG
            print("❌ [ERROR] Request failed: \(error)")
            #endif
            throw NetworkError.noConnection
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(NSError(domain: "NetworkClient", code: -1))
        }
        
        #if DEBUG
        print("⬅️ [RESPONSE] \(httpResponse.statusCode) \(url.absoluteString)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("   Body: \(responseString)")
        }
        #endif
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw NetworkError.decodingFailed(error)
            }
        case 401:
            throw NetworkError.unauthorized
        case 429:
            let retryAfter = Int(httpResponse.value(forHTTPHeaderField: "Retry-After") ?? "60") ?? 60
            throw NetworkError.rateLimited(retryAfter: retryAfter)
        case 500...599:
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        default:
            throw NetworkError.unknown(NSError(domain: "NetworkClient", code: httpResponse.statusCode))
        }
    }
}

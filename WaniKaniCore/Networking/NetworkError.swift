import Foundation

public enum NetworkError: Error, Equatable, CustomStringConvertible {
    case noConnection
    case unauthorized
    case rateLimited(retryAfter: Int)
    case serverError(statusCode: Int)
    case decodingFailed(Error)
    case invalidURL
    case unknown(Error)
    
    public var description: String {
        switch self {
        case .noConnection:
            return "No internet connection."
        case .unauthorized:
            return "Unauthorized. Please check your API token."
        case .rateLimited(let retryAfter):
            return "Rate limited. Try again in \(retryAfter) seconds."
        case .serverError(let statusCode):
            return "Server error (Status: \(statusCode))."
        case .decodingFailed(let error):
            if let decodingError = error as? DecodingError {
                return "Failed to process data: \(decodingError.detailedDescription)"
            }
            return "Failed to process data: \(error.localizedDescription)"
        case .invalidURL:
            return "Invalid URL."
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
    
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.noConnection, .noConnection),
             (.unauthorized, .unauthorized),
             (.invalidURL, .invalidURL):
            return true
        case let (.rateLimited(l), .rateLimited(r)):
            return l == r
        case let (.serverError(l), .serverError(r)):
            return l == r
        case (.decodingFailed, .decodingFailed),
             (.unknown, .unknown):
            // Error is not Equatable, so we just assume equal for now or compare descriptions
            // For testing purposes, we usually just care they are the same case
            return true 
        default:
            return false
        }
    }
}

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        return description
    }
}

private extension DecodingError {
    var detailedDescription: String {
        switch self {
        case .keyNotFound(let key, let context):
            return "Missing key '\(key.stringValue)' at path \(context.codingPath.pathString). \(context.debugDescription)"
        case .typeMismatch(let type, let context):
            return "Type mismatch '\(type)' at path \(context.codingPath.pathString). \(context.debugDescription)"
        case .valueNotFound(let type, let context):
            return "Missing value '\(type)' at path \(context.codingPath.pathString). \(context.debugDescription)"
        case .dataCorrupted(let context):
            return "Data corrupted at path \(context.codingPath.pathString). \(context.debugDescription)"
        @unknown default:
            return localizedDescription
        }
    }
}

private extension Array where Element == CodingKey {
    var pathString: String {
        guard !isEmpty else { return "<root>" }
        return map { key in
            if let intValue = key.intValue {
                return "[\(intValue)]"
            }
            return key.stringValue
        }
        .joined(separator: ".")
    }
}

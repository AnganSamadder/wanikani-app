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
            return true
        default:
            return false
        }
    }
}

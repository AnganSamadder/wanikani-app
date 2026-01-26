import Foundation

public enum NetworkError: Error, Equatable {
    case noConnection
    case unauthorized
    case rateLimited(retryAfter: Int)
    case serverError(statusCode: Int)
    case decodingFailed(Error)
    case invalidURL
    case unknown(Error)
    
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

import Foundation

public enum DiscourseError: Error, Equatable, LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case unauthorized
    case permissionDenied
    case rateLimited(retryAfter: Int)
    case server(statusCode: Int)
    case decodeFailure
    case transport

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid community URL."
        case .invalidResponse:
            return "Invalid response from community service."
        case .unauthorized:
            return "Community session is unauthorized."
        case .permissionDenied:
            return "Community action was denied."
        case .rateLimited(let retryAfter):
            return "Community rate limit reached. Retry in \(retryAfter) seconds."
        case .server(let statusCode):
            return "Community server error (\(statusCode))."
        case .decodeFailure:
            return "Unable to decode community response."
        case .transport:
            return "Community request failed due to connectivity issues."
        }
    }
}

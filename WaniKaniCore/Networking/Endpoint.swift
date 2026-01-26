import Foundation

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public struct Endpoint {
    public let path: String
    public let method: HTTPMethod
    public let headers: [String: String]
    public let queryParameters: [String: String]
    public let body: Data?
    
    public init(
        path: String,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        queryParameters: [String: String] = [:],
        body: Data? = nil
    ) {
        self.path = path
        self.method = method
        self.headers = headers
        self.queryParameters = queryParameters
        self.body = body
    }
}

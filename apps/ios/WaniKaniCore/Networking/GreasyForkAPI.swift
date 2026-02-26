import Foundation

public struct Script: Decodable, Identifiable {
    public let id: Int
    public let name: String
    public let description: String
    public let users: Int
    public let url: String
    public let codeURL: String
    public let createdAt: Date
    public let updatedAt: Date
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description
        case users = "daily_installs"
        case url
        case codeURL = "code_url"
        case createdAt = "created_at"
        case updatedAt = "code_updated_at"
    }
}

public final class GreasyForkAPI {
    private let networkClient: NetworkClient
    
    public init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    public func fetchScripts() async throws -> [Script] {
        let endpoint = Endpoint(
            path: "/scripts.json",
            method: .get,
            queryParameters: [
                "site": "wanikani.com",
                "sort": "updated"
            ]
        )
        
        // Note: GreasyFork API returns [Script] directly, not envelope
        return try await networkClient.request(endpoint)
    }
}

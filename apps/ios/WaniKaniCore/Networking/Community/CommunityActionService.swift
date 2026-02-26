import Foundation

public struct CommunityActionService: CommunityActionServiceProtocol {
    private let client: DiscourseAPIClientProtocol

    public init(client: DiscourseAPIClientProtocol) {
        self.client = client
    }

    public func createTopic(title: String, raw: String, categoryId: Int?) async throws -> CommunityTopic {
        try await client.createTopic(title: title, raw: raw, categoryId: categoryId)
    }

    public func createReply(topicId: Int, raw: String) async throws {
        try await client.reply(topicId: topicId, raw: raw)
    }

    public func editPost(postId: Int, raw: String) async throws {
        try await client.editPost(postId: postId, raw: raw)
    }

    public func likePost(postId: Int) async throws {
        try await client.like(postId: postId)
    }

    public func bookmarkPost(postId: Int) async throws {
        try await client.bookmark(postId: postId)
    }
}

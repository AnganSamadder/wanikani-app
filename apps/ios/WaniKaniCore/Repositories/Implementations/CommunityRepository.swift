import Foundation

public struct CommunityRepository: CommunityRepositoryProtocol {
    private let apiClient: DiscourseAPIClientProtocol
    private let actionService: CommunityActionServiceProtocol

    public init(
        apiClient: DiscourseAPIClientProtocol,
        actionService: CommunityActionServiceProtocol? = nil
    ) {
        self.apiClient = apiClient
        self.actionService = actionService ?? CommunityActionService(client: apiClient)
    }

    public func fetchCategories() async throws -> [CommunityCategory] {
        try await apiClient.fetchCategories()
    }

    public func fetchTopics(categoryId: Int?) async throws -> [CommunityTopic] {
        try await apiClient.fetchTopics(categoryId: categoryId)
    }

    public func searchTopics(query: String) async throws -> [CommunityTopic] {
        try await apiClient.searchTopics(query: query)
    }

    public func fetchTopic(id: Int) async throws -> CommunityTopicDetail {
        try await apiClient.fetchTopic(id: id)
    }

    public func createTopic(title: String, raw: String, categoryId: Int?) async throws -> CommunityTopic {
        try await actionService.createTopic(title: title, raw: raw, categoryId: categoryId)
    }

    public func createReply(topicId: Int, raw: String) async throws {
        try await actionService.createReply(topicId: topicId, raw: raw)
    }

    public func editPost(postId: Int, raw: String) async throws {
        try await actionService.editPost(postId: postId, raw: raw)
    }

    public func likePost(postId: Int) async throws {
        try await actionService.likePost(postId: postId)
    }

    public func bookmarkPost(postId: Int) async throws {
        try await actionService.bookmarkPost(postId: postId)
    }
}

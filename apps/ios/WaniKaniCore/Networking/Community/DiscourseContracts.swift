import Foundation

public struct CommunityCategory: Codable, Hashable, Sendable {
    public let id: Int
    public let name: String

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

public struct CommunityTopic: Codable, Hashable, Sendable {
    public let id: Int
    public let title: String
    public let postsCount: Int

    public init(id: Int, title: String, postsCount: Int) {
        self.id = id
        self.title = title
        self.postsCount = postsCount
    }
}

public struct CommunityPost: Codable, Hashable, Sendable {
    public let id: Int
    public let cookedHTML: String
    public let authorUsername: String

    public init(id: Int, cookedHTML: String, authorUsername: String) {
        self.id = id
        self.cookedHTML = cookedHTML
        self.authorUsername = authorUsername
    }
}

public struct CommunityTopicDetail: Codable, Hashable, Sendable {
    public let topic: CommunityTopic
    public let posts: [CommunityPost]

    public init(topic: CommunityTopic, posts: [CommunityPost]) {
        self.topic = topic
        self.posts = posts
    }
}

public protocol DiscourseAPIClientProtocol: Sendable {
    func fetchCategories() async throws -> [CommunityCategory]
    func fetchTopics(categoryId: Int?) async throws -> [CommunityTopic]
    func searchTopics(query: String) async throws -> [CommunityTopic]
    func fetchTopic(id: Int) async throws -> CommunityTopicDetail
    func createTopic(title: String, raw: String, categoryId: Int?) async throws -> CommunityTopic
    func reply(topicId: Int, raw: String) async throws
    func editPost(postId: Int, raw: String) async throws
    func like(postId: Int) async throws
    func bookmark(postId: Int) async throws
}

public protocol CommunityAuthSessionStore: Sendable {
    func currentAuthToken() async -> String?
    func setAuthToken(_ token: String?) async
}

public protocol CommunityActionServiceProtocol: Sendable {
    func createTopic(title: String, raw: String, categoryId: Int?) async throws -> CommunityTopic
    func createReply(topicId: Int, raw: String) async throws
    func editPost(postId: Int, raw: String) async throws
    func likePost(postId: Int) async throws
    func bookmarkPost(postId: Int) async throws
}

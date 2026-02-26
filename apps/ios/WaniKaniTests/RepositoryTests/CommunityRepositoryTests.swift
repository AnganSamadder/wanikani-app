import XCTest
import WaniKaniCore

final class CommunityRepositoryTests: XCTestCase {
    func test_fetchTopics_whenClientReturnsData_forwardsTopics() async throws {
        let topic = CommunityTopic(id: 10, title: "Topic", postsCount: 4)
        let client = MockDiscourseAPIClient(topics: [topic])
        let sut = CommunityRepository(apiClient: client)

        let result = try await sut.fetchTopics(categoryId: nil)

        XCTAssertEqual(result, [topic])
    }

    func test_createTopic_whenActionServiceSucceeds_returnsCreatedTopic() async throws {
        let client = MockDiscourseAPIClient()
        let createdTopic = CommunityTopic(id: 22, title: "New Topic", postsCount: 1)
        let actionService = MockCommunityActionService(createdTopic: createdTopic)
        let sut = CommunityRepository(apiClient: client, actionService: actionService)

        let result = try await sut.createTopic(title: "New Topic", raw: "Body", categoryId: 1)

        XCTAssertEqual(result, createdTopic)
    }
}

private struct MockDiscourseAPIClient: DiscourseAPIClientProtocol {
    var categories: [CommunityCategory] = []
    var topics: [CommunityTopic] = []
    var topicDetail: CommunityTopicDetail = CommunityTopicDetail(
        topic: CommunityTopic(id: 0, title: "", postsCount: 0),
        posts: []
    )

    func fetchCategories() async throws -> [CommunityCategory] {
        categories
    }

    func fetchTopics(categoryId: Int?) async throws -> [CommunityTopic] {
        topics
    }

    func searchTopics(query: String) async throws -> [CommunityTopic] {
        topics
    }

    func fetchTopic(id: Int) async throws -> CommunityTopicDetail {
        topicDetail
    }

    func createTopic(title: String, raw: String, categoryId: Int?) async throws -> CommunityTopic {
        CommunityTopic(id: 1, title: title, postsCount: 1)
    }

    func reply(topicId: Int, raw: String) async throws {}

    func editPost(postId: Int, raw: String) async throws {}

    func like(postId: Int) async throws {}

    func bookmark(postId: Int) async throws {}
}

private struct MockCommunityActionService: CommunityActionServiceProtocol {
    var createdTopic: CommunityTopic

    init(createdTopic: CommunityTopic = CommunityTopic(id: 1, title: "Topic", postsCount: 1)) {
        self.createdTopic = createdTopic
    }

    func createTopic(title: String, raw: String, categoryId: Int?) async throws -> CommunityTopic {
        createdTopic
    }

    func createReply(topicId: Int, raw: String) async throws {}

    func editPost(postId: Int, raw: String) async throws {}

    func likePost(postId: Int) async throws {}

    func bookmarkPost(postId: Int) async throws {}
}

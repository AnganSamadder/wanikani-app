import Foundation

public struct DiscourseAPIClient: DiscourseAPIClientProtocol {
    private let baseURL: URL
    private let session: URLSession
    private let authStore: CommunityAuthSessionStore
    private let decoder: JSONDecoder

    public init(
        baseURL: URL = URL(string: "https://community.wanikani.com")!,
        session: URLSession = .shared,
        authStore: CommunityAuthSessionStore = InMemoryCommunityAuthSessionStore()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.authStore = authStore
        self.decoder = JSONDecoder()
    }

    public func fetchCategories() async throws -> [CommunityCategory] {
        let data = try await performRequest(path: "/categories.json")
        let decoded = try decode(CategoriesResponse.self, from: data)
        return decoded.categoryList.categories.map {
            CommunityCategory(id: $0.id, name: $0.name)
        }
    }

    public func fetchTopics(categoryId: Int?) async throws -> [CommunityTopic] {
        let path: String
        if let categoryId {
            path = "/c/\(categoryId)/show.json"
        } else {
            path = "/latest.json"
        }
        let data = try await performRequest(path: path)
        let decoded = try decode(TopicListResponse.self, from: data)
        return decoded.topicList.topics.map {
            CommunityTopic(id: $0.id, title: $0.title, postsCount: $0.postsCount)
        }
    }

    public func searchTopics(query: String) async throws -> [CommunityTopic] {
        let data = try await performRequest(
            path: "/search/query.json",
            queryItems: [URLQueryItem(name: "q", value: query)]
        )
        let decoded = try decode(SearchResponse.self, from: data)
        return decoded.topics.map {
            CommunityTopic(id: $0.id, title: $0.title, postsCount: $0.postsCount)
        }
    }

    public func fetchTopic(id: Int) async throws -> CommunityTopicDetail {
        let data = try await performRequest(path: "/t/\(id).json")
        let decoded = try decode(TopicDetailResponse.self, from: data)
        let topic = CommunityTopic(id: decoded.id, title: decoded.title, postsCount: decoded.postsCount)
        let posts = decoded.postStream.posts.map {
            CommunityPost(id: $0.id, cookedHTML: $0.cooked, authorUsername: $0.username)
        }
        return CommunityTopicDetail(topic: topic, posts: posts)
    }

    public func createTopic(title: String, raw: String, categoryId: Int?) async throws -> CommunityTopic {
        struct Payload: Encodable {
            let title: String
            let raw: String
            let category: Int?
        }

        let data = try await performRequest(
            path: "/posts.json",
            method: "POST",
            encodedBody: try JSONEncoder().encode(Payload(title: title, raw: raw, category: categoryId)),
            requiresAuth: true
        )
        let decoded = try decode(CreateTopicResponse.self, from: data)
        return CommunityTopic(id: decoded.topicId, title: title, postsCount: 1)
    }

    public func reply(topicId: Int, raw: String) async throws {
        struct Payload: Encodable {
            let topicId: Int
            let raw: String

            enum CodingKeys: String, CodingKey {
                case topicId = "topic_id"
                case raw
            }
        }

        _ = try await performRequest(
            path: "/posts.json",
            method: "POST",
            encodedBody: try JSONEncoder().encode(Payload(topicId: topicId, raw: raw)),
            requiresAuth: true
        )
    }

    public func editPost(postId: Int, raw: String) async throws {
        struct Payload: Encodable {
            let post: PayloadPost

            struct PayloadPost: Encodable {
                let raw: String
            }
        }

        _ = try await performRequest(
            path: "/posts/\(postId).json",
            method: "PUT",
            encodedBody: try JSONEncoder().encode(Payload(post: .init(raw: raw))),
            requiresAuth: true
        )
    }

    public func like(postId: Int) async throws {
        try await sendPostAction(postId: postId, actionType: 2)
    }

    public func bookmark(postId: Int) async throws {
        try await sendPostAction(postId: postId, actionType: 3)
    }

    private func sendPostAction(postId: Int, actionType: Int) async throws {
        struct Payload: Encodable {
            let id: Int
            let postActionTypeId: Int

            enum CodingKeys: String, CodingKey {
                case id
                case postActionTypeId = "post_action_type_id"
            }
        }

        _ = try await performRequest(
            path: "/post_actions.json",
            method: "POST",
            encodedBody: try JSONEncoder().encode(Payload(id: postId, postActionTypeId: actionType)),
            requiresAuth: true
        )
    }

    private func performRequest(
        path: String,
        method: String = "GET",
        queryItems: [URLQueryItem] = [],
        encodedBody: Data? = nil,
        requiresAuth: Bool = false
    ) async throws -> Data {
        let normalizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        guard var components = URLComponents(url: baseURL.appendingPathComponent(normalizedPath), resolvingAgainstBaseURL: false) else {
            throw DiscourseError.invalidURL
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw DiscourseError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let encodedBody {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = encodedBody
        }

        if requiresAuth {
            guard let token = await authStore.currentAuthToken(), !token.isEmpty else {
                throw DiscourseError.unauthorized
            }
            request.setValue(token, forHTTPHeaderField: "User-Api-Key")
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw DiscourseError.transport
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DiscourseError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401:
            throw DiscourseError.unauthorized
        case 403:
            throw DiscourseError.permissionDenied
        case 429:
            let retryAfter = Int(httpResponse.value(forHTTPHeaderField: "Retry-After") ?? "") ?? 60
            throw DiscourseError.rateLimited(retryAfter: retryAfter)
        default:
            throw DiscourseError.server(statusCode: httpResponse.statusCode)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw DiscourseError.decodeFailure
        }
    }
}

private struct CategoriesResponse: Decodable {
    let categoryList: CategoryList

    enum CodingKeys: String, CodingKey {
        case categoryList = "category_list"
    }

    struct CategoryList: Decodable {
        let categories: [Category]

        struct Category: Decodable {
            let id: Int
            let name: String
        }
    }
}

private struct TopicListResponse: Decodable {
    let topicList: TopicList

    enum CodingKeys: String, CodingKey {
        case topicList = "topic_list"
    }

    struct TopicList: Decodable {
        let topics: [Topic]

        struct Topic: Decodable {
            let id: Int
            let title: String
            let postsCount: Int

            enum CodingKeys: String, CodingKey {
                case id
                case title
                case postsCount = "posts_count"
            }
        }
    }
}

private struct SearchResponse: Decodable {
    let topics: [Topic]

    struct Topic: Decodable {
        let id: Int
        let title: String
        let postsCount: Int

        enum CodingKeys: String, CodingKey {
            case id
            case title
            case postsCount = "posts_count"
        }
    }
}

private struct TopicDetailResponse: Decodable {
    let id: Int
    let title: String
    let postsCount: Int
    let postStream: PostStream

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case postsCount = "posts_count"
        case postStream = "post_stream"
    }

    struct PostStream: Decodable {
        let posts: [Post]

        struct Post: Decodable {
            let id: Int
            let cooked: String
            let username: String
        }
    }
}

private struct CreateTopicResponse: Decodable {
    let topicId: Int

    enum CodingKeys: String, CodingKey {
        case topicId = "topic_id"
    }
}

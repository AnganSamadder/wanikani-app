import Foundation

public final class WaniKaniAPI {
    private let networkClient: NetworkClient
    private let apiToken: String
    private let apiBasePath = "/v2"
    
    public init(networkClient: NetworkClient, apiToken: String) {
        self.networkClient = networkClient
        self.apiToken = apiToken
    }
    
    // MARK: - Private Helpers
    
    private func buildHeaders() -> [String: String] {
        [
            "Authorization": "Bearer \(apiToken)",
            "Wanikani-Revision": "20170710"
        ]
    }
    
    private func endpoint(path: String, queryParameters: [String: String] = [:]) -> Endpoint {
        Endpoint(
            path: path,
            method: .get,
            headers: buildHeaders(),
            queryParameters: queryParameters
        )
    }
    
    /// Parses a full nextURL from the API into path and query parameters
    /// The API returns full URLs like "https://api.wanikani.com/v2/subjects?page_after_id=1000"
    /// We need to strip the "/v2" prefix since our base URL already includes it
    private func parseNextURL(_ urlString: String) -> (path: String, queryParams: [String: String])? {
        guard let url = URL(string: urlString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        var path = components.path
        if path.hasPrefix(apiBasePath) {
            path.removeFirst(apiBasePath.count)
        }
        if path.isEmpty {
            path = "/"
        } else if !path.hasPrefix("/") {
            path = "/" + path
        }
        
        var queryParams: [String: String] = [:]
        for item in components.queryItems ?? [] {
            if let value = item.value {
                queryParams[item.name] = value
            }
        }
        
        return (path, queryParams)
    }
    
    // MARK: - User
    
    public func getUser() async throws -> User {
        let envelope: ResourceEnvelope<User> = try await networkClient.request(
            endpoint(path: "/user")
        )
        return envelope.data
    }
    
    // MARK: - Summary
    
    public func getSummary() async throws -> Summary {
        let summary: Summary = try await networkClient.request(
            endpoint(path: "/summary")
        )
        return summary
    }
    
    // MARK: - Subjects with Pagination
    
    public func getAllSubjects(
        types: [SubjectType]? = nil,
        levels: [Int]? = nil,
        updatedAfter: Date? = nil
    ) async throws -> [SubjectData] {
        var allSubjects: [SubjectData] = []
        var nextURL: String? = nil
        var isFirstRequest = true
        
        let iso8601Formatter = ISO8601DateFormatter()
        
        while isFirstRequest || nextURL != nil {
            let currentEndpoint: Endpoint
            
            if isFirstRequest {
                var queryParams: [String: String] = [:]
                
                if let types = types, !types.isEmpty {
                    queryParams["types"] = types.map { $0.rawValue }.joined(separator: ",")
                }
                if let levels = levels, !levels.isEmpty {
                    queryParams["levels"] = levels.map { String($0) }.joined(separator: ",")
                }
                if let updatedAfter = updatedAfter {
                    queryParams["updated_after"] = iso8601Formatter.string(from: updatedAfter)
                }
                
                currentEndpoint = endpoint(path: "/subjects", queryParameters: queryParams)
            } else if let next = nextURL, let parsed = parseNextURL(next) {
                currentEndpoint = endpoint(path: parsed.path, queryParameters: parsed.queryParams)
            } else {
                break
            }
            
            isFirstRequest = false
            
            let envelope: CollectionEnvelope<SubjectData> = try await networkClient.request(currentEndpoint)
            allSubjects.append(contentsOf: envelope.data)
            nextURL = envelope.pages.nextURL
        }
        
        return allSubjects
    }
    
    // MARK: - Assignments with Pagination
    
    public func getAssignments(
        subjectIDs: [Int]? = nil,
        availableBefore: Date? = nil,
        availableAfter: Date? = nil,
        updatedAfter: Date? = nil
    ) async throws -> [Assignment] {
        var allAssignments: [Assignment] = []
        var nextURL: String? = nil
        var isFirstRequest = true
        
        let iso8601Formatter = ISO8601DateFormatter()
        
        while isFirstRequest || nextURL != nil {
            let currentEndpoint: Endpoint
            
            if isFirstRequest {
                var queryParams: [String: String] = [:]
                
                if let subjectIDs = subjectIDs, !subjectIDs.isEmpty {
                    queryParams["subject_ids"] = subjectIDs.map { String($0) }.joined(separator: ",")
                }
                if let availableBefore = availableBefore {
                    queryParams["available_before"] = iso8601Formatter.string(from: availableBefore)
                }
                if let availableAfter = availableAfter {
                    queryParams["available_after"] = iso8601Formatter.string(from: availableAfter)
                }
                if let updatedAfter = updatedAfter {
                    queryParams["updated_after"] = iso8601Formatter.string(from: updatedAfter)
                }
                
                currentEndpoint = endpoint(path: "/assignments", queryParameters: queryParams)
            } else if let next = nextURL, let parsed = parseNextURL(next) {
                currentEndpoint = endpoint(path: parsed.path, queryParameters: parsed.queryParams)
            } else {
                break
            }
            
            isFirstRequest = false
            
            let envelope: CollectionEnvelope<Assignment> = try await networkClient.request(currentEndpoint)
            allAssignments.append(contentsOf: envelope.data)
            nextURL = envelope.pages.nextURL
        }
        
        return allAssignments
    }
    
    // MARK: - Assignment Actions
    
    public func startAssignment(id: Int, startedAt: Date? = nil) async throws -> Assignment {
        struct AssignmentStartRequest: Encodable {
            let assignment: AssignmentStartData
        }
        
        struct AssignmentStartData: Encodable {
            let startedAt: String?
            
            enum CodingKeys: String, CodingKey {
                case startedAt = "started_at"
            }
        }
        
        let iso8601Formatter = ISO8601DateFormatter()
        let startedAtString = startedAt.map { iso8601Formatter.string(from: $0) }
        
        let request = AssignmentStartRequest(
            assignment: AssignmentStartData(startedAt: startedAtString)
        )
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        var headers = buildHeaders()
        headers["Content-Type"] = "application/json"
        
        let endpoint = Endpoint(
            path: "/assignments/\(id)/start",
            method: .put,
            headers: headers,
            body: body
        )
        
        let envelope: ResourceEnvelope<AssignmentData> = try await networkClient.request(endpoint)
        
        return Assignment(
            id: id,
            object: "assignment",
            url: "",
            dataUpdatedAt: nil,
            data: envelope.data
        )
    }
    
    // MARK: - Review Statistics with Pagination
    
    public func getReviewStatistics(
        subjectIDs: [Int]? = nil,
        subjectTypes: [SubjectType]? = nil,
        updatedAfter: Date? = nil
    ) async throws -> [ReviewStatistic] {
        var allStats: [ReviewStatistic] = []
        var nextURL: String? = nil
        var isFirstRequest = true
        
        let iso8601Formatter = ISO8601DateFormatter()
        
        while isFirstRequest || nextURL != nil {
            let currentEndpoint: Endpoint
            
            if isFirstRequest {
                var queryParams: [String: String] = [:]
                
                if let subjectIDs = subjectIDs, !subjectIDs.isEmpty {
                    queryParams["subject_ids"] = subjectIDs.map { String($0) }.joined(separator: ",")
                }
                if let subjectTypes = subjectTypes, !subjectTypes.isEmpty {
                    queryParams["subject_types"] = subjectTypes.map { $0.rawValue }.joined(separator: ",")
                }
                if let updatedAfter = updatedAfter {
                    queryParams["updated_after"] = iso8601Formatter.string(from: updatedAfter)
                }
                
                currentEndpoint = endpoint(path: "/review_statistics", queryParameters: queryParams)
            } else if let next = nextURL, let parsed = parseNextURL(next) {
                currentEndpoint = endpoint(path: parsed.path, queryParameters: parsed.queryParams)
            } else {
                break
            }
            
            isFirstRequest = false
            
            let envelope: CollectionEnvelope<ReviewStatistic> = try await networkClient.request(currentEndpoint)
            allStats.append(contentsOf: envelope.data)
            nextURL = envelope.pages.nextURL
        }
        
        return allStats
    }
    
    // MARK: - Level Progressions with Pagination
    
    public func getLevelProgressions(
        updatedAfter: Date? = nil
    ) async throws -> [LevelProgression] {
        var allProgressions: [LevelProgression] = []
        var nextURL: String? = nil
        var isFirstRequest = true
        
        let iso8601Formatter = ISO8601DateFormatter()
        
        while isFirstRequest || nextURL != nil {
            let currentEndpoint: Endpoint
            
            if isFirstRequest {
                var queryParams: [String: String] = [:]
                
                if let updatedAfter = updatedAfter {
                    queryParams["updated_after"] = iso8601Formatter.string(from: updatedAfter)
                }
                
                currentEndpoint = endpoint(path: "/level_progressions", queryParameters: queryParams)
            } else if let next = nextURL, let parsed = parseNextURL(next) {
                currentEndpoint = endpoint(path: parsed.path, queryParameters: parsed.queryParams)
            } else {
                break
            }
            
            isFirstRequest = false
            
            let envelope: CollectionEnvelope<LevelProgression> = try await networkClient.request(currentEndpoint)
            allProgressions.append(contentsOf: envelope.data)
            nextURL = envelope.pages.nextURL
        }
        
        return allProgressions
    }
    
    // MARK: - Reviews
    
    public func submitReview(
        assignmentID: Int,
        incorrectMeaningAnswers: Int,
        incorrectReadingAnswers: Int
    ) async throws -> Review {
        let reviewRequest = ReviewRequest(
            assignmentID: assignmentID,
            incorrectMeaningAnswers: incorrectMeaningAnswers,
            incorrectReadingAnswers: incorrectReadingAnswers
        )
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(ReviewRequestWrapper(review: reviewRequest))
        
        var headers = buildHeaders()
        headers["Content-Type"] = "application/json"
        
        let reviewEndpoint = Endpoint(
            path: "/reviews",
            method: .post,
            headers: headers,
            body: body
        )
        
        let envelope: ResourceEnvelope<ReviewData> = try await networkClient.request(reviewEndpoint)
        
        return Review(
            id: 0,
            object: "review",
            url: "",
            dataUpdatedAt: nil,
            data: envelope.data
        )
    }
}

// MARK: - Review Request Types

private struct ReviewRequest: Encodable {
    let assignmentID: Int
    let incorrectMeaningAnswers: Int
    let incorrectReadingAnswers: Int
    
    enum CodingKeys: String, CodingKey {
        case assignmentID = "assignment_id"
        case incorrectMeaningAnswers = "incorrect_meaning_answers"
        case incorrectReadingAnswers = "incorrect_reading_answers"
    }
}

private struct ReviewRequestWrapper: Encodable {
    let review: ReviewRequest
}

// MARK: - SubjectData wrapper for heterogeneous subjects

public struct SubjectData: Decodable, Identifiable {
    public let id: Int
    public let object: String
    public let url: String
    public let dataUpdatedAt: Date?
    public let data: SubjectContent
    
    private enum CodingKeys: String, CodingKey {
        case id, object, url, data
        case dataUpdatedAt = "data_updated_at"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        object = try container.decode(String.self, forKey: .object)
        url = try container.decode(String.self, forKey: .url)
        dataUpdatedAt = try container.decodeIfPresent(Date.self, forKey: .dataUpdatedAt)
        
        switch object {
        case "radical":
            data = .radical(try container.decode(RadicalData.self, forKey: .data))
        case "kanji":
            data = .kanji(try container.decode(KanjiData.self, forKey: .data))
        case "vocabulary", "kana_vocabulary":
            data = .vocabulary(try container.decode(VocabularyData.self, forKey: .data))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .object,
                in: container,
                debugDescription: "Unknown subject type: \(object)"
            )
        }
    }
    
    public init(id: Int, object: String, url: String, dataUpdatedAt: Date?, data: SubjectContent) {
        self.id = id
        self.object = object
        self.url = url
        self.dataUpdatedAt = dataUpdatedAt
        self.data = data
    }
}

public enum SubjectContent: Equatable {
    case radical(RadicalData)
    case kanji(KanjiData)
    case vocabulary(VocabularyData)
}

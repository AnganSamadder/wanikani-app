import XCTest
@testable import WaniKaniCore

final class MockNetworkClient: NetworkClient {
    var responses: [Any] = []
    var capturedEndpoints: [Endpoint] = []
    private var callIndex = 0
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        capturedEndpoints.append(endpoint)
        
        guard callIndex < responses.count else {
            throw NetworkError.unknown(NSError(domain: "MockNetworkClient", code: -1))
        }
        
        let response = responses[callIndex]
        callIndex += 1
        
        if let error = response as? Error {
            throw error
        }
        
        guard let typedResponse = response as? T else {
            throw NetworkError.decodingFailed(
                NSError(domain: "MockNetworkClient", code: -1)
            )
        }
        
        return typedResponse
    }
}

final class WaniKaniAPITests: XCTestCase {
    private var sut: WaniKaniAPI!
    private var mockClient: MockNetworkClient!
    
    override func setUp() {
        super.setUp()
        mockClient = MockNetworkClient()
        sut = WaniKaniAPI(networkClient: mockClient, apiToken: "test-token")
    }
    
    override func tearDown() {
        sut = nil
        mockClient = nil
        super.tearDown()
    }
    
    // MARK: - Headers Tests
    
    func test_request_includesAuthorizationHeader() async throws {
        // Given
        let envelope = makeUserEnvelope()
        mockClient.responses = [envelope]
        
        // When
        _ = try await sut.getUser()
        
        // Then
        XCTAssertEqual(mockClient.capturedEndpoints.count, 1)
        let endpoint = mockClient.capturedEndpoints[0]
        XCTAssertEqual(endpoint.headers["Authorization"], "Bearer test-token")
    }
    
    func test_request_includesWaniKaniRevisionHeader() async throws {
        // Given
        let envelope = makeUserEnvelope()
        mockClient.responses = [envelope]
        
        // When
        _ = try await sut.getUser()
        
        // Then
        let endpoint = mockClient.capturedEndpoints[0]
        XCTAssertEqual(endpoint.headers["Wanikani-Revision"], "20170710")
    }
    
    // MARK: - getUser Tests
    
    func test_getUser_returnsCorrectUser() async throws {
        // Given
        let expectedUser = makeTestUser()
        let envelope = ResourceEnvelope(
            object: "user",
            url: "https://api.wanikani.com/v2/user",
            dataUpdatedAt: nil,
            data: expectedUser
        )
        mockClient.responses = [envelope]
        
        // When
        let user = try await sut.getUser()
        
        // Then
        XCTAssertEqual(user.username, "test_user")
        XCTAssertEqual(user.level, 5)
    }
    
    func test_getUser_callsCorrectEndpoint() async throws {
        // Given
        mockClient.responses = [makeUserEnvelope()]
        
        // When
        _ = try await sut.getUser()
        
        // Then
        XCTAssertEqual(mockClient.capturedEndpoints[0].path, "/user")
        XCTAssertEqual(mockClient.capturedEndpoints[0].method, .get)
    }
    
    // MARK: - getSummary Tests
    
    func test_getSummary_returnsCorrectSummary() async throws {
        // Given
        let expectedSummary = makeTestSummary()
        mockClient.responses = [expectedSummary]
        
        // When
        let summary = try await sut.getSummary()
        
        // Then
        XCTAssertEqual(summary.object, "report")
        XCTAssertEqual(summary.data.lessons.count, 1)
        XCTAssertEqual(summary.data.reviews.count, 1)
    }
    
    func test_getSummary_callsCorrectEndpoint() async throws {
        // Given
        mockClient.responses = [makeTestSummary()]
        
        // When
        _ = try await sut.getSummary()
        
        // Then
        XCTAssertEqual(mockClient.capturedEndpoints[0].path, "/summary")
    }
    
    // MARK: - getAllSubjects Tests
    
    func test_getAllSubjects_paginatesCorrectly() async throws {
        // Given
        let page1 = makeSubjectCollectionEnvelope(
            subjects: [makeTestSubjectData(id: 1)],
            nextURL: "https://api.wanikani.com/v2/subjects?page_after_id=1"
        )
        let page2 = makeSubjectCollectionEnvelope(
            subjects: [makeTestSubjectData(id: 2)],
            nextURL: nil
        )
        mockClient.responses = [page1, page2]
        
        // When
        let subjects = try await sut.getAllSubjects()
        
        // Then
        XCTAssertEqual(subjects.count, 2)
        XCTAssertEqual(subjects[0].id, 1)
        XCTAssertEqual(subjects[1].id, 2)
        XCTAssertEqual(mockClient.capturedEndpoints.count, 2)
    }
    
    func test_getAllSubjects_withTypeFilter_sendsCorrectQueryParameter() async throws {
        // Given
        let page = makeSubjectCollectionEnvelope(subjects: [], nextURL: nil)
        mockClient.responses = [page]
        
        // When
        _ = try await sut.getAllSubjects(types: [.kanji, .vocabulary])
        
        // Then
        let queryParams = mockClient.capturedEndpoints[0].queryParameters
        XCTAssertEqual(queryParams["types"], "kanji,vocabulary")
    }
    
    func test_getAllSubjects_withLevelFilter_sendsCorrectQueryParameter() async throws {
        // Given
        let page = makeSubjectCollectionEnvelope(subjects: [], nextURL: nil)
        mockClient.responses = [page]
        
        // When
        _ = try await sut.getAllSubjects(levels: [1, 2, 3])
        
        // Then
        let queryParams = mockClient.capturedEndpoints[0].queryParameters
        XCTAssertEqual(queryParams["levels"], "1,2,3")
    }
    
    // MARK: - getAssignments Tests
    
    func test_getAssignments_paginatesCorrectly() async throws {
        // Given
        let page1 = makeAssignmentCollectionEnvelope(
            assignments: [makeTestAssignment(id: 100)],
            nextURL: "https://api.wanikani.com/v2/assignments?page_after_id=100"
        )
        let page2 = makeAssignmentCollectionEnvelope(
            assignments: [makeTestAssignment(id: 101)],
            nextURL: nil
        )
        mockClient.responses = [page1, page2]
        
        // When
        let assignments = try await sut.getAssignments()
        
        // Then
        XCTAssertEqual(assignments.count, 2)
        XCTAssertEqual(assignments[0].id, 100)
        XCTAssertEqual(assignments[1].id, 101)
    }
    
    func test_getAssignments_withSubjectIDsFilter_sendsCorrectQueryParameter() async throws {
        // Given
        let page = makeAssignmentCollectionEnvelope(assignments: [], nextURL: nil)
        mockClient.responses = [page]
        
        // When
        _ = try await sut.getAssignments(subjectIDs: [1, 2, 3])
        
        // Then
        let queryParams = mockClient.capturedEndpoints[0].queryParameters
        XCTAssertEqual(queryParams["subject_ids"], "1,2,3")
    }
    
    func test_getAssignments_withDateFilters_sendsCorrectQueryParameters() async throws {
        // Given
        let page = makeAssignmentCollectionEnvelope(assignments: [], nextURL: nil)
        mockClient.responses = [page]
        let testDate = Date(timeIntervalSince1970: 1700000000)
        
        // When
        _ = try await sut.getAssignments(availableBefore: testDate, availableAfter: testDate)
        
        // Then
        let queryParams = mockClient.capturedEndpoints[0].queryParameters
        XCTAssertNotNil(queryParams["available_before"])
        XCTAssertNotNil(queryParams["available_after"])
    }
    
    // MARK: - submitReview Tests
    
    func test_submitReview_sendsCorrectPOSTBody() async throws {
        // Given
        let reviewData = makeTestReviewData()
        let envelope = ResourceEnvelope(
            object: "review",
            url: "https://api.wanikani.com/v2/reviews/123",
            dataUpdatedAt: nil,
            data: reviewData
        )
        mockClient.responses = [envelope]
        
        // When
        _ = try await sut.submitReview(
            assignmentID: 456,
            incorrectMeaningAnswers: 1,
            incorrectReadingAnswers: 2
        )
        
        // Then
        let endpoint = mockClient.capturedEndpoints[0]
        XCTAssertEqual(endpoint.path, "/reviews")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNotNil(endpoint.body)
        XCTAssertEqual(endpoint.headers["Content-Type"], "application/json")
    }
    
    func test_submitReview_returnsCorrectReview() async throws {
        // Given
        let reviewData = makeTestReviewData()
        let envelope = ResourceEnvelope(
            object: "review",
            url: "https://api.wanikani.com/v2/reviews/123",
            dataUpdatedAt: nil,
            data: reviewData
        )
        mockClient.responses = [envelope]
        
        // When
        let review = try await sut.submitReview(
            assignmentID: 456,
            incorrectMeaningAnswers: 1,
            incorrectReadingAnswers: 2
        )
        
        // Then
        XCTAssertEqual(review.data.assignmentID, 456)
        XCTAssertEqual(review.data.incorrectMeaningAnswers, 1)
        XCTAssertEqual(review.data.incorrectReadingAnswers, 2)
    }
    
    // MARK: - Test Helpers
    
    private func makeTestUser() -> User {
        User(
            id: "user-123",
            username: "test_user",
            level: 5,
            profileURL: "https://www.wanikani.com/users/test_user",
            startedAt: Date(),
            subscription: Subscription(active: true, type: .recurring, maxLevelGranted: 60),
            preferences: Preferences(
                defaultVoiceActorID: 1,
                lessonsAutoplayAudio: true,
                lessonsBatchSize: 5,
                lessonsPresentationOrder: "ascending_level_then_subject",
                reviewsAutoplayAudio: true,
                reviewsDisplaySRSIndicator: true
            )
        )
    }
    
    private func makeUserEnvelope() -> ResourceEnvelope<User> {
        ResourceEnvelope(
            object: "user",
            url: "https://api.wanikani.com/v2/user",
            dataUpdatedAt: nil,
            data: makeTestUser()
        )
    }
    
    private func makeTestSummary() -> Summary {
        Summary(
            object: "report",
            url: "https://api.wanikani.com/v2/summary",
            dataUpdatedAt: nil,
            data: SummaryData(
                lessons: [LessonSummary(availableAt: Date(), subjectIDs: [1, 2, 3])],
                reviews: [ReviewSummary(availableAt: Date(), subjectIDs: [4, 5, 6])],
                nextReviewsAt: Date()
            )
        )
    }
    
    private func makeTestSubjectData(id: Int) -> SubjectData {
        SubjectData(
            id: id,
            object: "radical",
            url: "https://api.wanikani.com/v2/subjects/\(id)",
            dataUpdatedAt: nil,
            data: .radical(RadicalData(
                createdAt: Date(),
                level: 1,
                slug: "ground",
                documentURL: "https://www.wanikani.com/radicals/ground",
                characters: "一",
                characterImages: [],
                meanings: [Meaning(meaning: "Ground", primary: true, acceptedAnswer: true)],
                auxiliaryMeanings: [],
                amalgamationSubjectIDs: [],
                meaningMnemonic: "Test mnemonic",
                lessonPosition: 0,
                spacedRepetitionSystemID: 1
            ))
        )
    }
    
    private func makeSubjectCollectionEnvelope(subjects: [SubjectData], nextURL: String?) -> CollectionEnvelope<SubjectData> {
        CollectionEnvelope(
            object: "collection",
            url: "https://api.wanikani.com/v2/subjects",
            pages: CollectionPage(perPage: 500, nextURL: nextURL, previousURL: nil),
            totalCount: subjects.count,
            dataUpdatedAt: nil,
            data: subjects
        )
    }
    
    private func makeTestAssignment(id: Int) -> Assignment {
        Assignment(
            id: id,
            object: "assignment",
            url: "https://api.wanikani.com/v2/assignments/\(id)",
            dataUpdatedAt: nil,
            data: AssignmentData(
                createdAt: Date(),
                subjectID: 1,
                subjectType: .radical,
                srsStage: 5,
                availableAt: Date()
            )
        )
    }
    
    private func makeAssignmentCollectionEnvelope(assignments: [Assignment], nextURL: String?) -> CollectionEnvelope<Assignment> {
        CollectionEnvelope(
            object: "collection",
            url: "https://api.wanikani.com/v2/assignments",
            pages: CollectionPage(perPage: 500, nextURL: nextURL, previousURL: nil),
            totalCount: assignments.count,
            dataUpdatedAt: nil,
            data: assignments
        )
    }
    
    private func makeTestReviewData() -> ReviewData {
        ReviewData(
            createdAt: Date(),
            assignmentID: 456,
            subjectID: 1,
            spacedRepetitionSystemID: 1,
            startingSRSStage: 5,
            endingSRSStage: 6,
            incorrectMeaningAnswers: 1,
            incorrectReadingAnswers: 2
        )
    }
}

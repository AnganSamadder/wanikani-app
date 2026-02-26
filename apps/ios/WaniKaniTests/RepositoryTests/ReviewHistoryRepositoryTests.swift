import XCTest
@testable import WaniKaniCore

@MainActor
final class ReviewHistoryRepositoryTests: XCTestCase {
    private var sut: ReviewHistoryRepository!
    private var mockClient: MockNetworkClient!
    private var api: WaniKaniAPI!
    private var persistence: PersistenceManager!
    private var preferences: PreferencesManager!
    private var defaultsSuiteName: String!

    override func setUp() {
        super.setUp()
        mockClient = MockNetworkClient()
        api = WaniKaniAPI(networkClient: mockClient, apiToken: "token")
        persistence = PersistenceManager(inMemory: true)

        defaultsSuiteName = "ReviewHistoryRepositoryTests-\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: defaultsSuiteName)!
        userDefaults.removePersistentDomain(forName: defaultsSuiteName)
        preferences = PreferencesManager(userDefaults: userDefaults)

        sut = ReviewHistoryRepository(
            api: api,
            persistenceManager: persistence,
            preferencesManager: preferences
        )
    }

    override func tearDown() {
        if let defaultsSuiteName {
            UserDefaults(suiteName: defaultsSuiteName)?.removePersistentDomain(forName: defaultsSuiteName)
        }
        sut = nil
        mockClient = nil
        api = nil
        persistence = nil
        preferences = nil
        super.tearDown()
    }

    func test_syncReviewHistory_secondCallUsesUpdatedAfter() async throws {
        let now = Date()
        mockClient.responses = [
            makeReviewCollection(reviews: [makeReview(id: 1, assignmentID: 10, subjectID: 100, createdAt: now)]),
            makeReviewCollection(reviews: [makeReview(id: 2, assignmentID: 11, subjectID: 101, createdAt: now)])
        ]

        try await sut.syncReviewHistory()
        try await sut.syncReviewHistory()

        XCTAssertEqual(mockClient.capturedEndpoints.count, 2)
        XCTAssertNil(mockClient.capturedEndpoints[0].queryParameters["updated_after"])
        XCTAssertNotNil(mockClient.capturedEndpoints[1].queryParameters["updated_after"])
    }

    func test_fetchDailyReviewCounts_groupsByStartOfDay() async throws {
        let calendar = Calendar.current
        let day1 = calendar.startOfDay(for: Date())
        let day2 = calendar.date(byAdding: .day, value: 1, to: day1)!

        let reviews = [
            makeReview(id: 10, assignmentID: 200, subjectID: 300, createdAt: calendar.date(byAdding: .hour, value: 1, to: day1)!),
            makeReview(id: 11, assignmentID: 201, subjectID: 301, createdAt: calendar.date(byAdding: .hour, value: 10, to: day1)!),
            makeReview(id: 12, assignmentID: 202, subjectID: 302, createdAt: calendar.date(byAdding: .hour, value: 2, to: day2)!)
        ]
        try persistence.saveReviews(reviews)

        let counts = try await sut.fetchDailyReviewCounts(from: day1, to: calendar.date(byAdding: .hour, value: 23, to: day2)!)

        XCTAssertEqual(counts[day1], 2)
        XCTAssertEqual(counts[day2], 1)
    }

    private func makeReview(id: Int, assignmentID: Int, subjectID: Int, createdAt: Date) -> Review {
        Review(
            id: id,
            object: "review",
            url: "https://api.wanikani.com/v2/reviews/\(id)",
            dataUpdatedAt: createdAt,
            data: ReviewData(
                createdAt: createdAt,
                assignmentID: assignmentID,
                subjectID: subjectID,
                spacedRepetitionSystemID: 1,
                startingSRSStage: 1,
                endingSRSStage: 2,
                incorrectMeaningAnswers: 0,
                incorrectReadingAnswers: 0
            )
        )
    }

    private func makeReviewCollection(reviews: [Review]) -> CollectionEnvelope<Review> {
        CollectionEnvelope(
            object: "collection",
            url: "https://api.wanikani.com/v2/reviews",
            pages: CollectionPage(perPage: 500, nextURL: nil, previousURL: nil),
            totalCount: reviews.count,
            dataUpdatedAt: Date(),
            data: reviews
        )
    }
}

import XCTest
import WaniKaniCore
@testable import WaniKani

@MainActor
final class SummaryRepositoryTests: XCTestCase {
    private var sut: SummaryRepository!
    private var api: WaniKaniAPI!
    private var mockClient: MockNetworkClient!
    
    override func setUp() {
        super.setUp()
        mockClient = MockNetworkClient()
        api = WaniKaniAPI(networkClient: mockClient, apiToken: "test-token")
        sut = SummaryRepository(api: api)
    }
    
    override func tearDown() {
        sut = nil
        api = nil
        mockClient = nil
        super.tearDown()
    }
    
    func test_fetchSummary_success() async throws {
        // Given
        let expectedSummary = makeTestSummary()
        mockClient.responses = [expectedSummary]
        
        // When
        let summary = try await sut.fetchSummary()
        
        // Then
        XCTAssertEqual(summary.object, "report")
        XCTAssertEqual(summary.data.lessons.count, 1)
        XCTAssertEqual(summary.data.lessons[0].subjectIDs, [1, 2, 3])
    }
    
    func test_fetchSummary_failure() async throws {
        // Given
        let expectedError = NSError(domain: "test", code: 123, userInfo: nil)
        mockClient.responses = [expectedError]
        
        // When/Then
        do {
            _ = try await sut.fetchSummary()
            XCTFail("Expected error to be thrown")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "test")
            XCTAssertEqual(nsError.code, 123)
        }
    }
    
    // MARK: - Helpers
    
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
}

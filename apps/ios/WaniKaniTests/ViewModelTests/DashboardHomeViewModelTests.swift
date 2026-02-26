import XCTest
import WaniKaniCore
@testable import WaniKani

@MainActor
final class DashboardHomeViewModelTests: XCTestCase {
    private var repository: MockDashboardRepository!
    private var sut: DashboardHomeViewModel!

    override func setUp() {
        super.setUp()
        repository = MockDashboardRepository()
        sut = DashboardHomeViewModel(repository: repository)
    }

    override func tearDown() {
        sut = nil
        repository = nil
        super.tearDown()
    }

    func test_load_whenRepositorySucceeds_setsLoadedCounts() async {
        repository.mockSummary = Summary(
            object: "report",
            url: "https://api.wanikani.com/v2/summary",
            dataUpdatedAt: nil,
            data: SummaryData(
                lessons: [LessonSummary(availableAt: Date().addingTimeInterval(-10), subjectIDs: [1, 2])],
                reviews: [ReviewSummary(availableAt: Date().addingTimeInterval(-10), subjectIDs: [10, 11, 12])],
                nextReviewsAt: Date().addingTimeInterval(3600)
            )
        )

        await sut.load()

        XCTAssertEqual(sut.state, .loaded)
        XCTAssertEqual(sut.lessonsCount, 2)
        XCTAssertEqual(sut.reviewsCount, 3)
        XCTAssertNotNil(sut.nextReviewsAt)
    }

    func test_load_whenRepositoryFails_setsFailedState() async {
        repository.error = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "boom"])

        await sut.load()

        if case .failed(let message) = sut.state {
            XCTAssertEqual(message, "boom")
        } else {
            XCTFail("Expected failed state")
        }
    }
}

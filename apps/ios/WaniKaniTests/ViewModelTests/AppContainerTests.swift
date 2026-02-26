import XCTest
@testable import WaniKani

@MainActor
final class AppContainerTests: XCTestCase {
    func test_routeCatalog_containsExpectedPrimaryTabs() {
        let container = AppContainer()
        let primaryRoutes = container.routeCatalog.filter(\.isPrimaryTab)

        XCTAssertEqual(primaryRoutes.count, 5)
        XCTAssertEqual(primaryRoutes.map(\.label), ["Today", "Reviews", "Lessons", "Progress", "Settings"])
    }

    func test_viewModelFactories_returnInstances() {
        let container = AppContainer()

        XCTAssertNotNil(container.makeDashboardViewModel())
        XCTAssertNotNil(container.makeReviewsViewModel())
        XCTAssertNotNil(container.makeLessonsViewModel())
    }
}

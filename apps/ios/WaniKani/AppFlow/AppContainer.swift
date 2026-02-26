import Foundation
import WaniKaniCore

protocol AppContainerProtocol: Sendable {
    var routeCatalog: [AppRouteDescriptor] { get }
    @MainActor
    func makeDashboardViewModel() -> DashboardHomeViewModel
    @MainActor
    func makeReviewsViewModel() -> ReviewSessionViewModel
    @MainActor
    func makeLessonsViewModel() -> LessonSessionViewModel
    @MainActor
    func makeProgressOverviewViewModel() -> ProgressOverviewViewModel
}

struct AppContainer: AppContainerProtocol {
    let routeCatalog: [AppRouteDescriptor]

    init() {
        self.routeCatalog = AppRouteCatalog.all
    }

    @MainActor
    func makeDashboardViewModel() -> DashboardHomeViewModel {
        DashboardHomeViewModel(repository: dashboardRepository)
    }

    @MainActor
    func makeReviewsViewModel() -> ReviewSessionViewModel {
        ReviewSessionViewModel(
            reviewSessionRepository: reviewSessionRepository,
            subjectDetailRepository: subjectDetailRepository
        )
    }

    @MainActor
    func makeLessonsViewModel() -> LessonSessionViewModel {
        LessonSessionViewModel(repository: lessonSessionRepository)
    }

    @MainActor
    private var apiToken: String {
        AuthenticationManager.shared.apiToken ?? ""
    }

    @MainActor
    private var api: WaniKaniAPI {
        WaniKaniAPI(networkClient: URLSessionNetworkClient(), apiToken: apiToken)
    }

    @MainActor
    private var persistenceManager: PersistenceManager {
        PersistenceManager.shared
    }

    @MainActor
    private var summaryRepository: SummaryRepositoryProtocol {
        SummaryRepository(api: api)
    }

    @MainActor
    private var assignmentRepository: AssignmentRepositoryProtocol {
        AssignmentRepository(persistenceManager: persistenceManager)
    }

    @MainActor
    private var subjectRepository: SubjectRepositoryProtocol {
        SubjectRepository(persistenceManager: persistenceManager)
    }

    @MainActor
    private var reviewRepository: ReviewRepositoryProtocol {
        ReviewRepository(api: api)
    }

    @MainActor
    private var dashboardRepository: DashboardRepositoryProtocol {
        DashboardRepository(summaryRepository: summaryRepository)
    }

    @MainActor
    private var reviewSessionRepository: ReviewSessionRepositoryProtocol {
        ReviewSessionRepository(
            assignmentRepository: assignmentRepository,
            reviewRepository: reviewRepository
        )
    }

    @MainActor
    private var lessonSessionRepository: LessonSessionRepositoryProtocol {
        LessonSessionRepository(
            persistenceManager: persistenceManager,
            subjectRepository: subjectRepository
        )
    }

    @MainActor
    private var subjectDetailRepository: SubjectDetailRepositoryProtocol {
        SubjectDetailRepository(subjectRepository: subjectRepository)
    }

    @MainActor
    private var reviewHistoryRepository: ReviewHistoryRepository {
        ReviewHistoryRepository(
            api: api,
            persistenceManager: persistenceManager,
            preferencesManager: PreferencesManager()
        )
    }

    @MainActor
    func makeProgressOverviewViewModel() -> ProgressOverviewViewModel {
        ProgressOverviewViewModel(reviewHistoryRepository: reviewHistoryRepository)
    }
}

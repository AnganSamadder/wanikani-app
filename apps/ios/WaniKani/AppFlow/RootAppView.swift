import SwiftUI

@MainActor
struct RootAppFlowView: View {
    private let container: AppContainerProtocol
    @StateObject private var dashboardViewModel: DashboardHomeViewModel
    @StateObject private var reviewsViewModel: ReviewSessionViewModel
    @StateObject private var lessonsViewModel: LessonSessionViewModel
    @StateObject private var progressViewModel: ProgressOverviewViewModel
    @State private var selectedTab: AppRoute = .dashboard
    @State private var didPrefetchQueues = false

    init(container: AppContainerProtocol = AppContainer()) {
        self.container = container
        _dashboardViewModel = StateObject(wrappedValue: container.makeDashboardViewModel())
        _reviewsViewModel = StateObject(wrappedValue: container.makeReviewsViewModel())
        _lessonsViewModel = StateObject(wrappedValue: container.makeLessonsViewModel())
        _progressViewModel = StateObject(wrappedValue: container.makeProgressOverviewViewModel())
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(container.routeCatalog.filter(\.isPrimaryTab), id: \.route) { descriptor in
                NavigationStack {
                    primaryRootView(for: descriptor.route)
                }
                .tabItem {
                    Label(descriptor.label, systemImage: descriptor.systemImage)
                }
                .tag(descriptor.route)
            }
        }
        .tint(WKColor.kanji)
        .task {
            await prefetchQueuesIfNeeded()
        }
    }

    @ViewBuilder
    private func primaryRootView(for route: AppRoute) -> some View {
        switch route {
        case .dashboard:
            DashboardHomeView(viewModel: dashboardViewModel)
        case .reviews:
            ReviewSessionView(viewModel: reviewsViewModel, onNavigateToTab: { route in
                selectedTab = route
            })
        case .lessons:
            LessonSessionView(viewModel: lessonsViewModel)
        case .statistics:
            ProgressOverviewView(viewModel: progressViewModel)
        case .settings:
            SettingsHubView()
        case .subjects:
            SubjectCatalogView()
        case .search:
            SubjectSearchView()
        case .extraStudy:
            ExtraStudyView()
        case .community:
            CommunityHubView()
        }
    }

    private func prefetchQueuesIfNeeded() async {
        guard !didPrefetchQueues else { return }
        didPrefetchQueues = true

        async let reviewsPrefetch: Void = reviewsViewModel.prefetchIfNeeded()
        async let lessonsPrefetch: Void = lessonsViewModel.prefetchIfNeeded()
        _ = await (reviewsPrefetch, lessonsPrefetch)
    }

}

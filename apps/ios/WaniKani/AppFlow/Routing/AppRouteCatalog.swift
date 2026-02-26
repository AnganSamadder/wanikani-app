import Foundation

struct AppRouteDescriptor: Hashable, Sendable {
    let route: AppRoute
    let label: String
    let systemImage: String
    let isPrimaryTab: Bool
}

enum AppRouteCatalog {
    static let all: [AppRouteDescriptor] = [
        .init(route: .dashboard, label: "Today", systemImage: "sun.max.fill", isPrimaryTab: true),
        .init(route: .reviews, label: "Reviews", systemImage: "flame.fill", isPrimaryTab: true),
        .init(route: .lessons, label: "Lessons", systemImage: "book.fill", isPrimaryTab: true),
        .init(route: .statistics, label: "Progress", systemImage: "chart.bar.fill", isPrimaryTab: true),
        .init(route: .settings, label: "Settings", systemImage: "gearshape.fill", isPrimaryTab: true),
        .init(route: .subjects, label: "Subjects", systemImage: "text.book.closed.fill", isPrimaryTab: false),
        .init(route: .search, label: "Search", systemImage: "magnifyingglass", isPrimaryTab: false),
        .init(route: .extraStudy, label: "Extra Study", systemImage: "bolt.fill", isPrimaryTab: false),
        .init(route: .community, label: "Community", systemImage: "person.3.fill", isPrimaryTab: false)
    ]

    static var primaryTabs: [AppRouteDescriptor] {
        all.filter(\.isPrimaryTab)
    }

    static var extendedRoutes: [AppRouteDescriptor] {
        all.filter { !$0.isPrimaryTab }
    }
}

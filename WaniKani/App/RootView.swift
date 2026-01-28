import SwiftUI
import WaniKaniCore

struct RootView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var themeController = ThemeController.shared
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                content
            } else {
                LoginView()
            }
        }
        .preferredColorScheme(themeController.preferredColorScheme)
    }
    
    @ViewBuilder
    var content: some View {
        #if os(iOS)
        if horizontalSizeClass == .compact {
            TabNavigationView()
        } else {
            SidebarNavigationView()
        }
        #else
        SidebarNavigationView()
        #endif
    }
}

struct TabNavigationView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Today", systemImage: "sun.max.fill")
            }
            
            NavigationStack {
                ReviewsView()
            }
            .tabItem {
                Label("Reviews", systemImage: "flame.fill")
            }
            
            NavigationStack {
                LessonsView()
            }
            .tabItem {
                Label("Lessons", systemImage: "book.fill")
            }
            
            NavigationStack {
                StatisticsView()
            }
            .tabItem {
                Label("Progress", systemImage: "chart.bar.fill")
            }
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(WKColor.kanji)
    }
}

struct SidebarNavigationView: View {
    @State private var selection: NavigationItem? = .dashboard
    
    enum NavigationItem: Hashable {
        case dashboard, reviews, lessons, statistics, settings
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section {
                    NavigationLink(value: NavigationItem.dashboard) {
                        Label("Today", systemImage: "sun.max.fill")
                    }
                    NavigationLink(value: NavigationItem.reviews) {
                        Label("Reviews", systemImage: "flame.fill")
                    }
                    NavigationLink(value: NavigationItem.lessons) {
                        Label("Lessons", systemImage: "book.fill")
                    }
                }
                
                Section {
                    NavigationLink(value: NavigationItem.statistics) {
                        Label("Progress", systemImage: "chart.bar.fill")
                    }
                    NavigationLink(value: NavigationItem.settings) {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("WaniKani")
        } detail: {
            switch selection {
            case .dashboard: DashboardView()
            case .reviews: ReviewsView()
            case .lessons: LessonsView()
            case .statistics: StatisticsView()
            case .settings: SettingsView()
            case .none: 
                WKEmptyState.noContent(
                    title: "Welcome",
                    message: "Select an item from the sidebar to get started."
                )
            }
        }
        .tint(WKColor.kanji)
    }
}

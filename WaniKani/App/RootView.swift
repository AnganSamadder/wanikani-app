import SwiftUI
import WaniKaniCore

struct RootView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    
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
                Label("Dashboard", systemImage: "house.fill")
            }
            
            NavigationStack {
                ReviewsView()
            }
            .tabItem {
                Label("Reviews", systemImage: "checkmark.circle.fill")
            }
            
            NavigationStack {
                LessonsView()
            }
            .tabItem {
                Label("Lessons", systemImage: "book.fill")
            }
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

struct SidebarNavigationView: View {
    @State private var selection: NavigationItem? = .dashboard
    
    enum NavigationItem: Hashable {
        case dashboard, reviews, lessons, settings
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                NavigationLink(value: NavigationItem.dashboard) {
                    Label("Dashboard", systemImage: "house.fill")
                }
                NavigationLink(value: NavigationItem.reviews) {
                    Label("Reviews", systemImage: "checkmark.circle.fill")
                }
                NavigationLink(value: NavigationItem.lessons) {
                    Label("Lessons", systemImage: "book.fill")
                }
                NavigationLink(value: NavigationItem.settings) {
                    Label("Settings", systemImage: "gear")
                }
            }
            .navigationTitle("WaniKani")
        } detail: {
            switch selection {
            case .dashboard: DashboardView()
            case .reviews: ReviewsView()
            case .lessons: LessonsView()
            case .settings: SettingsView()
            case .none: Text("Select an item")
            }
        }
    }
}

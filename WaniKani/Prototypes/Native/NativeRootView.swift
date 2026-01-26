import SwiftUI

struct NativeRootView: View {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    var body: some View {
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
                Text("Dashboard") // Placeholder
            }
            .tabItem {
                Label("Dashboard", systemImage: "house.fill")
            }
            
            NavigationStack {
                Text("Reviews") // Placeholder
            }
            .tabItem {
                Label("Reviews", systemImage: "checkmark.circle.fill")
            }
            
            NavigationStack {
                Text("Lessons") // Placeholder
            }
            .tabItem {
                Label("Lessons", systemImage: "book.fill")
            }
            
            NavigationStack {
                Text("Settings") // Placeholder
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
            case .dashboard: Text("Dashboard")
            case .reviews: Text("Reviews")
            case .lessons: Text("Lessons")
            case .settings: Text("Settings")
            case .none: Text("Select an item")
            }
        }
    }
}

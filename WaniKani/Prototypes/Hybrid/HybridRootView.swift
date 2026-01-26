import SwiftUI

struct HybridRootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HybridDashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "house.fill")
            }
            
            NavigationStack {
                // Reuse Native Reviews for now, or Hybrid?
                // Plan says: Hybrid strategy = Best of both
                // Reviews: Web (complex logic) or Native (offline)? 
                // Let's use WebView for Reviews/Lessons (complex UI)
                WaniKaniWebView(url: URL(string: "https://www.wanikani.com/review")!)
                    .navigationTitle("Reviews")
            }
            .tabItem {
                Label("Reviews", systemImage: "checkmark.circle.fill")
            }
            
            NavigationStack {
                WaniKaniWebView(url: URL(string: "https://www.wanikani.com/lesson")!)
                    .navigationTitle("Lessons")
            }
            .tabItem {
                Label("Lessons", systemImage: "book.fill")
            }
            
            NavigationStack {
                // Reuse Native Settings
                NativeSettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

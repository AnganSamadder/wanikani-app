import SwiftUI

struct WebViewRootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DashboardWebView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "house.fill")
            }
            
            NavigationStack {
                ReviewsWebView()
            }
            .tabItem {
                Label("Reviews", systemImage: "checkmark.circle.fill")
            }
            
            NavigationStack {
                LessonsWebView()
            }
            .tabItem {
                Label("Lessons", systemImage: "book.fill")
            }
            
            NavigationStack {
                ForumsWebView()
            }
            .tabItem {
                Label("Forums", systemImage: "bubble.left.and.bubble.right.fill")
            }
            
            NavigationStack {
                StatisticsWebView(username: "me")
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle.fill")
            }
        }
    }
}

#Preview {
    WebViewRootView()
}

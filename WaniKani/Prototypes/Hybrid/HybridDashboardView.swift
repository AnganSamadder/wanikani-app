import SwiftUI
import WaniKaniCore

struct HybridDashboardView: View {
    @StateObject private var viewModel = NativeDashboardViewModel(persistence: .shared)
    
    var body: some View {
        VStack(spacing: 0) {
            // Native Header
            if let user = viewModel.user {
                UserProfileHeader(user: user)
                    .padding(.bottom)
                    .background(Color(.systemBackground))
                    .shadow(radius: 1)
                    .zIndex(1)
            }
            
            // WebView Content
            WaniKaniWebView(url: URL(string: "https://www.wanikani.com/dashboard")!)
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
    }
}

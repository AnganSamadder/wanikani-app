import SwiftUI

struct DashboardWebView: View {
    var body: some View {
        WaniKaniWebView(url: URL(string: "https://www.wanikani.com/dashboard")!)
            .navigationTitle("Dashboard")
    }
}

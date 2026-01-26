import SwiftUI

struct ReviewsWebView: View {
    var body: some View {
        WaniKaniWebView(url: URL(string: "https://www.wanikani.com/review")!)
            .navigationTitle("Reviews")
    }
}

import SwiftUI

struct ForumsWebView: View {
    var body: some View {
        WaniKaniWebView(url: URL(string: "https://community.wanikani.com")!)
            .navigationTitle("Forums")
    }
}

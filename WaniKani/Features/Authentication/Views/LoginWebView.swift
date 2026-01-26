import SwiftUI

struct LoginWebView: View {
    var body: some View {
        WaniKaniWebView(url: URL(string: "https://www.wanikani.com/login")!)
            .navigationTitle("Login")
    }
}

import SwiftUI

struct LessonsWebView: View {
    var body: some View {
        WaniKaniWebView(url: URL(string: "https://www.wanikani.com/lesson")!)
            .navigationTitle("Lessons")
    }
}

import SwiftUI
import WaniKaniCore

struct NativeLessonsView: View {
    @StateObject private var viewModel = NativeLessonsViewModel()
    
    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading Lessons...")
            case .empty:
                ContentUnavailableView("No Lessons", systemImage: "book.closed", description: Text("Check back later!"))
            case .learning(let subject):
                Text("Learning: \(subject.object)") // Placeholder for detailed lesson view
            case .quizzing(let subject, _):
                Text("Quiz: \(subject.object)") // Placeholder for quiz view
            case .complete:
                Text("Lessons Complete!")
            }
        }
        .navigationTitle("Lessons")
    }
}

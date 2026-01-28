import SwiftUI
import WaniKaniCore

struct ReviewsView: View {
    @StateObject private var viewModel: ReviewsViewModel
    
    init() {
        let persistence = PersistenceManager.shared
        let apiToken = AuthenticationManager.shared.apiToken ?? ""
        let api = WaniKaniAPI(networkClient: URLSessionNetworkClient(), apiToken: apiToken)
        
        let assignmentRepo = AssignmentRepository(persistenceManager: persistence)
        let subjectRepo = SubjectRepository(persistenceManager: persistence)
        let reviewRepo = ReviewRepository(api: api)
        
        _viewModel = StateObject(wrappedValue: ReviewsViewModel(
            assignmentRepo: assignmentRepo,
            subjectRepo: subjectRepo,
            reviewRepo: reviewRepo
        ))
    }
    
    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading Reviews...")
            case .empty:
                ContentUnavailableView("No Reviews", systemImage: "checkmark.circle", description: Text("You're all caught up!"))
            case .reviewing:
                if let item = viewModel.currentItem {
                    VStack(spacing: 20) {
                        Text(item.subject.characters ?? item.subject.slug)
                            .font(.system(size: 64))
                        
                        Text(item.questionType == .meaning ? "Meaning" : "Reading")
                            .font(.headline)
                            .foregroundStyle(item.questionType == .meaning ? .blue : .primary)
                        
                        // Placeholder for input
                        Button("Submit Correct (Fake)") {
                            Task {
                                await viewModel.submitAnswer("correct")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    Text("Loading item...")
                }
            case .complete:
                ContentUnavailableView("Session Complete", systemImage: "star.fill", description: Text("Good job!"))
            case .error(let message):
                ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(message))
            }
        }
        .navigationTitle("Reviews")
        .task {
            // Only load if not already loaded or reviewing
            if case .loading = viewModel.state {
                await viewModel.loadReviews()
            }
        }
    }
}

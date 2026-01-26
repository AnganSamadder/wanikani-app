import SwiftUI
import WaniKaniCore

struct NativeReviewsView: View {
    @StateObject private var viewModel = NativeReviewsViewModel()
    
    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading Reviews...")
            case .empty:
                ContentUnavailableView("No Reviews", systemImage: "checkmark.circle", description: Text("You're all caught up!"))
            case .reviewing:
                Text("Review Session Placeholder")
            case .complete:
                Text("Review Complete Placeholder")
            }
        }
        .navigationTitle("Reviews")
    }
}

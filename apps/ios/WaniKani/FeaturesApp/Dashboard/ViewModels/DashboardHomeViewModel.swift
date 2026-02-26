import Foundation
import SwiftUI
import WaniKaniCore

@MainActor
final class DashboardHomeViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var lessonsCount: Int = 0
    @Published private(set) var reviewsCount: Int = 0
    @Published private(set) var nextReviewsAt: Date?

    private let repository: DashboardRepositoryProtocol

    init(repository: DashboardRepositoryProtocol) {
        self.repository = repository
    }

    func load() async {
        state = .loading

        do {
            let summary = try await repository.fetchDashboardSummary()
            lessonsCount = summary.data.availableLessonsCount
            reviewsCount = summary.data.availableReviewsCount
            nextReviewsAt = summary.data.nextReviewsAt
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    var nextReviewText: String {
        guard let nextReviewsAt else {
            return "No upcoming reviews"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: nextReviewsAt, relativeTo: Date())
    }
}

import Foundation
import WaniKaniCore

@MainActor
final class ProgressOverviewViewModel: ObservableObject {
    @Published var dailyCounts: [Date: Int] = [:]
    @Published var isSyncing: Bool = false

    private let reviewHistoryRepository: ReviewHistoryRepositoryProtocol

    init(reviewHistoryRepository: ReviewHistoryRepositoryProtocol) {
        self.reviewHistoryRepository = reviewHistoryRepository
    }

    func load() async {
        isSyncing = true
        defer { isSyncing = false }

        do {
            try await reviewHistoryRepository.syncReviewHistory()
            let to = Date()
            let from = Calendar.current.date(byAdding: .year, value: -1, to: to) ?? to
            dailyCounts = try await reviewHistoryRepository.fetchDailyReviewCounts(from: from, to: to)
        } catch {
            // Non-fatal: show what we have cached
            let to = Date()
            let from = Calendar.current.date(byAdding: .year, value: -1, to: to) ?? to
            dailyCounts = (try? await reviewHistoryRepository.fetchDailyReviewCounts(from: from, to: to)) ?? [:]
        }
    }
}

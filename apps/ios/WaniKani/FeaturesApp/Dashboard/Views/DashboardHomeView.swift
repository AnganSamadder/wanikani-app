import SwiftUI

struct DashboardHomeView: View {
    @StateObject private var viewModel: DashboardHomeViewModel

    init(viewModel: DashboardHomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        AppScreen(title: "Today", subtitle: "Lessons and reviews at a glance") {
            AppSectionTitle(icon: "chart.pie.fill", text: "Session Summary")
            HStack(spacing: 10) {
                AppMetricTile(label: "Lessons", value: "\(viewModel.lessonsCount)", tint: WKColor.warning)
                AppMetricTile(label: "Reviews", value: "\(viewModel.reviewsCount)", tint: WKColor.kanji)
            }

            AppCard {
                Text("Level Progress")
                    .font(.headline.weight(.semibold))
                ProgressView(value: normalizedProgressValue)
                    .tint(WKColor.success)
                Text("Active queue coverage")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            AppCard {
                Text("Upcoming")
                    .font(.headline.weight(.semibold))
                Text("Next review window \(viewModel.nextReviewText).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView("Loading summary...")
                        .font(.subheadline)
                case .loaded:
                    AppPrimaryButton(title: "Refresh") {
                        Task { await viewModel.load() }
                    }
                case .failed(let message):
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                    AppPrimaryButton(title: "Retry") {
                        Task { await viewModel.load() }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.state == .idle {
                await viewModel.load()
            }
        }
    }

    private var normalizedProgressValue: Double {
        let total = viewModel.lessonsCount + viewModel.reviewsCount
        guard total > 0 else { return 0.0 }
        return min(max(Double(viewModel.reviewsCount) / Double(total), 0), 1)
    }
}

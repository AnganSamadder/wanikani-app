import SwiftUI
import WaniKaniCore

struct ProgressOverviewView: View {
    @StateObject private var viewModel: ProgressOverviewViewModel

    init(viewModel: ProgressOverviewViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        AppScreen(title: "Progress", subtitle: "SRS stages and streak trends") {
            AppSectionTitle(icon: "chart.bar.fill", text: "SRS Distribution")
            HStack(spacing: 10) {
                AppMetricTile(label: "Apprentice", value: "88", tint: WKColor.warning)
                AppMetricTile(label: "Guru", value: "214", tint: WKColor.kanji)
            }
            HStack(spacing: 10) {
                AppMetricTile(label: "Master", value: "396", tint: WKColor.radical)
                AppMetricTile(label: "Enlightened", value: "520", tint: WKColor.vocabulary)
            }

            AppCard {
                Text("Accuracy")
                    .font(.headline.weight(.semibold))
                ProgressView(value: 0.93)
                    .tint(WKColor.success)
                Text("93% last 7 days")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            AppSectionTitle(icon: "calendar.badge.clock", text: "Review History")

            if viewModel.isSyncing {
                ProgressView("Syncing review history…")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                AppCard {
                    ScrollView(.horizontal, showsIndicators: false) {
                        ReviewHeatmapView(counts: viewModel.dailyCounts)
                            .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }
}

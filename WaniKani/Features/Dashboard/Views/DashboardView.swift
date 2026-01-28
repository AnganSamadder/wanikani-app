import SwiftUI
import WaniKaniCore

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    
    init() {
        let apiToken = AuthenticationManager.shared.apiToken ?? ""
        let api = WaniKaniAPI(networkClient: URLSessionNetworkClient(), apiToken: apiToken)
        let summaryRepo = SummaryRepository(api: api)
        _viewModel = StateObject(wrappedValue: DashboardViewModel(persistence: .shared, summaryRepository: summaryRepo))
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: WKSpacing.lg) {
                // MARK: - Header
                headerSection
                
                // MARK: - Primary Actions
                if viewModel.reviews > 0 || viewModel.lessons > 0 {
                    primaryActionsSection
                }
                
                // MARK: - Content
                if viewModel.isLoading && viewModel.user == nil {
                    loadingSection
                } else if let error = viewModel.errorMessage, viewModel.user == nil {
                    errorSection(error)
                } else {
                    statsSection
                }
            }
            .padding(.horizontal, WKSpacing.md)
            .padding(.top, WKSpacing.md)
            .padding(.bottom, WKSpacing.xxl)
        }
        .background(WKColor.surfaceGrouped)
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            if viewModel.user == nil && !viewModel.isLoading {
                await viewModel.loadData()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: WKSpacing.xxs) {
                Text(greetingText)
                    .font(WKTypography.body)
                    .foregroundStyle(WKColor.textSecondary)
                
                if let user = viewModel.user {
                    Text(user.username)
                        .font(WKTypography.title)
                        .foregroundStyle(WKColor.textPrimary)
                } else {
                    WKSkeletonView(width: 120, height: 28)
                }
            }
            
            Spacer()
            
            if let user = viewModel.user {
                LevelBadge(level: user.level)
            }
        }
        .padding(.vertical, WKSpacing.xs)
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }
    
    // MARK: - Primary Actions
    
    private var primaryActionsSection: some View {
        VStack(spacing: WKSpacing.sm) {
            if viewModel.reviews > 0 {
                WKActionTile(
                    title: "Reviews Available",
                    count: viewModel.reviews,
                    color: WKColor.radical,
                    icon: "flame.fill"
                ) {
                    // Navigate to reviews
                }
            }
            
            if viewModel.lessons > 0 {
                WKActionTile(
                    title: "New Lessons",
                    count: viewModel.lessons,
                    color: WKColor.kanji,
                    icon: "book.fill"
                ) {
                    // Navigate to lessons
                }
            }
        }
    }
    
    // MARK: - Loading Section
    
    private var loadingSection: some View {
        VStack(spacing: WKSpacing.md) {
            WKSkeletonCard()
            HStack(spacing: WKSpacing.sm) {
                WKSkeletonCard()
                WKSkeletonCard()
            }
        }
    }
    
    // MARK: - Error Section
    
    private func errorSection(_ message: String) -> some View {
        WKCard {
            VStack(spacing: WKSpacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(WKColor.warning)
                
                VStack(spacing: WKSpacing.xs) {
                    Text("Unable to Load")
                        .font(WKTypography.titleSmall)
                        .foregroundStyle(WKColor.textPrimary)
                    
                    Text(message)
                        .font(WKTypography.body)
                        .foregroundStyle(WKColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                WKButton("Retry", icon: "arrow.clockwise", style: .primary) {
                    Task {
                        await viewModel.refresh()
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, WKSpacing.lg)
        }
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(spacing: WKSpacing.md) {
            // Quick Stats Row
            if viewModel.reviews == 0 && viewModel.lessons == 0 {
                allCaughtUpCard
            }
            
            // Study Progress
            if let user = viewModel.user {
                studyProgressCard(user: user)
            }
            
            // Next Review
            nextReviewCard
        }
    }
    
    private var allCaughtUpCard: some View {
        WKCard {
            HStack(spacing: WKSpacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(WKColor.success)
                
                VStack(alignment: .leading, spacing: WKSpacing.xxs) {
                    Text("All Caught Up!")
                        .font(WKTypography.titleSmall)
                        .foregroundStyle(WKColor.textPrimary)
                    
                    Text("No reviews or lessons right now")
                        .font(WKTypography.body)
                        .foregroundStyle(WKColor.textSecondary)
                }
                
                Spacer()
            }
        }
    }
    
    private func studyProgressCard(user: User) -> some View {
        WKCard {
            VStack(alignment: .leading, spacing: WKSpacing.md) {
                HStack {
                    Text("Level Progress")
                        .font(WKTypography.titleSmall)
                        .foregroundStyle(WKColor.textPrimary)
                    
                    Spacer()
                    
                    Text("Level \(user.level)")
                        .font(WKTypography.captionMedium)
                        .foregroundStyle(WKColor.textSecondary)
                }
                
                // Progress indicators by type
                VStack(spacing: WKSpacing.sm) {
                    ProgressRow(
                        title: "Radicals",
                        progress: 0.85,
                        color: WKColor.radical
                    )
                    ProgressRow(
                        title: "Kanji",
                        progress: 0.62,
                        color: WKColor.kanji
                    )
                    ProgressRow(
                        title: "Vocabulary",
                        progress: 0.45,
                        color: WKColor.vocabulary
                    )
                }
            }
        }
    }
    
    private var nextReviewCard: some View {
        WKCard {
            HStack(spacing: WKSpacing.md) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(WKColor.textTertiary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: WKSpacing.xxs) {
                    Text("Next Reviews")
                        .font(WKTypography.captionMedium)
                        .foregroundStyle(WKColor.textSecondary)
                    
                    if let summary = viewModel.summary,
                       let nextHour = summary.data.nextReviewsAt {
                        Text(nextHour, style: .relative)
                            .font(WKTypography.titleSmall)
                            .foregroundStyle(WKColor.textPrimary)
                    } else {
                        Text("No upcoming reviews")
                            .font(WKTypography.titleSmall)
                            .foregroundStyle(WKColor.textPrimary)
                    }
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Supporting Views

private struct LevelBadge: View {
    let level: Int
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(level)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(WKColor.kanji)
            
            Text("LEVEL")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(WKColor.textTertiary)
        }
        .padding(.horizontal, WKSpacing.sm)
        .padding(.vertical, WKSpacing.xs)
        .background(WKColor.kanjiBackground)
        .clipShape(RoundedRectangle(cornerRadius: WKRadius.md, style: .continuous))
    }
}

private struct ProgressRow: View {
    let title: String
    let progress: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: WKSpacing.sm) {
            Text(title)
                .font(WKTypography.captionMedium)
                .foregroundStyle(WKColor.textSecondary)
                .frame(width: 80, alignment: .leading)
            
            WKProgressBar(progress: progress, color: color, height: 6)
            
            Text("\(Int(progress * 100))%")
                .font(WKTypography.captionMedium)
                .foregroundStyle(WKColor.textTertiary)
                .frame(width: 36, alignment: .trailing)
                .monospacedDigit()
        }
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
}

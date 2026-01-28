import SwiftUI
import WaniKaniCore

struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel(persistence: .shared)
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: WKSpacing.lg) {
                // MARK: - Level Progress Hero
                levelProgressSection
                
                // MARK: - Quick Stats
                quickStatsSection
                
                // MARK: - SRS Distribution
                srsDistributionSection
                
                // MARK: - Level Timeline
                levelTimelineSection
            }
            .padding(.horizontal, WKSpacing.md)
            .padding(.top, WKSpacing.md)
            .padding(.bottom, WKSpacing.xxl)
        }
        .background(WKColor.surfaceGrouped)
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Level Progress Section
    
    private var levelProgressSection: some View {
        WKCard(padding: WKSpacing.lg) {
            VStack(spacing: WKSpacing.lg) {
                // Level display
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: WKSpacing.xxs) {
                        Text("Current Level")
                            .font(WKTypography.captionMedium)
                            .foregroundStyle(WKColor.textSecondary)
                        
                        HStack(alignment: .firstTextBaseline, spacing: WKSpacing.xs) {
                            Text("\(viewModel.level)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(WKColor.kanji)
                            
                            Text("/ 60")
                                .font(WKTypography.titleMedium)
                                .foregroundStyle(WKColor.textTertiary)
                        }
                    }
                    
                    Spacer()
                    
                    // Circular progress
                    ZStack {
                        Circle()
                            .stroke(WKColor.surfaceTertiary, lineWidth: 8)
                        
                        Circle()
                            .trim(from: 0, to: min(Double(viewModel.level) / 60.0, 1.0))
                            .stroke(
                                WKColor.kanji.gradient,
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 0) {
                            Text("\(Int(Double(viewModel.level) / 60.0 * 100))%")
                                .font(WKTypography.bodyMedium)
                                .foregroundStyle(WKColor.textPrimary)
                        }
                    }
                    .frame(width: 64, height: 64)
                }
                
                // Progress to next level
                VStack(alignment: .leading, spacing: WKSpacing.xs) {
                    HStack {
                        Text("Progress to Level \(viewModel.level + 1)")
                            .font(WKTypography.captionMedium)
                            .foregroundStyle(WKColor.textSecondary)
                        
                        Spacer()
                        
                        Text("85%")
                            .font(WKTypography.captionMedium)
                            .foregroundStyle(WKColor.textSecondary)
                    }
                    
                    WKProgressBar(progress: 0.85, color: WKColor.kanji, height: 8)
                }
            }
        }
    }
    
    // MARK: - Quick Stats Section
    
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: WKSpacing.sm) {
            Text("Overview")
                .font(WKTypography.titleSmall)
                .foregroundStyle(WKColor.textPrimary)
                .padding(.horizontal, WKSpacing.xxs)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: WKSpacing.sm),
                GridItem(.flexible(), spacing: WKSpacing.sm)
            ], spacing: WKSpacing.sm) {
                StatCard(
                    title: "Accuracy",
                    value: String(format: "%.1f%%", viewModel.accuracy),
                    subtitle: "Last 30 days",
                    icon: "chart.line.uptrend.xyaxis",
                    color: WKColor.success
                )
                
                StatCard(
                    title: "Items Learned",
                    value: "847",
                    subtitle: "Total",
                    icon: "brain.head.profile",
                    color: WKColor.vocabulary
                )
                
                StatCard(
                    title: "Reviews Done",
                    value: "4,521",
                    subtitle: "All time",
                    icon: "checkmark.circle.fill",
                    color: WKColor.radical
                )
                
                StatCard(
                    title: "Day Streak",
                    value: "12",
                    subtitle: "Keep it up!",
                    icon: "flame.fill",
                    color: .orange
                )
            }
        }
    }
    
    // MARK: - SRS Distribution Section
    
    private var srsDistributionSection: some View {
        VStack(alignment: .leading, spacing: WKSpacing.sm) {
            Text("SRS Distribution")
                .font(WKTypography.titleSmall)
                .foregroundStyle(WKColor.textPrimary)
                .padding(.horizontal, WKSpacing.xxs)
            
            WKCard {
                VStack(spacing: WKSpacing.md) {
                    // SRS stages
                    SRSStageRow(stage: "Apprentice", count: 89, total: 847, color: .orange)
                    SRSStageRow(stage: "Guru", count: 234, total: 847, color: WKColor.kanji)
                    SRSStageRow(stage: "Master", count: 156, total: 847, color: WKColor.radical)
                    SRSStageRow(stage: "Enlightened", count: 298, total: 847, color: WKColor.vocabulary)
                    SRSStageRow(stage: "Burned", count: 70, total: 847, color: WKColor.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Level Timeline Section
    
    private var levelTimelineSection: some View {
        VStack(alignment: .leading, spacing: WKSpacing.sm) {
            Text("Level Timeline")
                .font(WKTypography.titleSmall)
                .foregroundStyle(WKColor.textPrimary)
                .padding(.horizontal, WKSpacing.xxs)
            
            WKCard {
                VStack(spacing: WKSpacing.md) {
                    // Average level time
                    HStack {
                        VStack(alignment: .leading, spacing: WKSpacing.xxs) {
                            Text("Average Level Time")
                                .font(WKTypography.captionMedium)
                                .foregroundStyle(WKColor.textSecondary)
                            
                            Text("12 days")
                                .font(WKTypography.titleMedium)
                                .foregroundStyle(WKColor.textPrimary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: WKSpacing.xxs) {
                            Text("Fastest Level")
                                .font(WKTypography.captionMedium)
                                .foregroundStyle(WKColor.textSecondary)
                            
                            Text("8 days")
                                .font(WKTypography.titleMedium)
                                .foregroundStyle(WKColor.success)
                        }
                    }
                    
                    Divider()
                    
                    // Recent levels
                    VStack(alignment: .leading, spacing: WKSpacing.sm) {
                        Text("Recent Levels")
                            .font(WKTypography.captionMedium)
                            .foregroundStyle(WKColor.textSecondary)
                        
                        HStack(spacing: WKSpacing.xs) {
                            ForEach(1...5, id: \.self) { i in
                                let level = viewModel.level - 5 + i
                                if level > 0 {
                                    LevelBubble(level: level, isCurrent: i == 5)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

private struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        WKCard {
            VStack(alignment: .leading, spacing: WKSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
                
                VStack(alignment: .leading, spacing: WKSpacing.xxs) {
                    Text(value)
                        .font(WKTypography.titleMedium)
                        .foregroundStyle(WKColor.textPrimary)
                    
                    Text(title)
                        .font(WKTypography.captionMedium)
                        .foregroundStyle(WKColor.textSecondary)
                    
                    Text(subtitle)
                        .font(WKTypography.caption)
                        .foregroundStyle(WKColor.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct SRSStageRow: View {
    let stage: String
    let count: Int
    let total: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: WKSpacing.sm) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            Text(stage)
                .font(WKTypography.body)
                .foregroundStyle(WKColor.textPrimary)
            
            Spacer()
            
            Text("\(count)")
                .font(WKTypography.bodyMedium)
                .foregroundStyle(WKColor.textPrimary)
                .monospacedDigit()
            
            WKProgressBar(
                progress: Double(count) / Double(total),
                color: color,
                height: 4
            )
            .frame(width: 60)
        }
    }
}

private struct LevelBubble: View {
    let level: Int
    let isCurrent: Bool
    
    var body: some View {
        Text("\(level)")
            .font(WKTypography.captionMedium)
            .foregroundStyle(isCurrent ? .white : WKColor.textPrimary)
            .frame(width: 32, height: 32)
            .background(isCurrent ? WKColor.kanji : WKColor.surfaceTertiary)
            .clipShape(Circle())
    }
}

#Preview {
    NavigationStack {
        StatisticsView()
    }
}

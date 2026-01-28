import SwiftUI

// MARK: - WKLoadingView

/// A centered loading indicator with optional message.
public struct WKLoadingView: View {
    let message: String?
    
    public init(_ message: String? = nil) {
        self.message = message
    }
    
    public var body: some View {
        VStack(spacing: WKSpacing.md) {
            ProgressView()
                .scaleEffect(1.2)
            
            if let message = message {
                Text(message)
                    .font(WKTypography.body)
                    .foregroundStyle(WKColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - WKProgressBar

/// A horizontal progress bar with optional label.
public struct WKProgressBar: View {
    let progress: Double
    let color: Color
    let height: CGFloat
    let showLabel: Bool
    
    public init(
        progress: Double,
        color: Color = .accentColor,
        height: CGFloat = 8,
        showLabel: Bool = false
    ) {
        self.progress = min(max(progress, 0), 1)
        self.color = color
        self.height = height
        self.showLabel = showLabel
    }
    
    public var body: some View {
        VStack(alignment: .trailing, spacing: WKSpacing.xxs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(WKColor.surfaceTertiary)
                        .frame(height: height)
                    
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(color.gradient)
                        .frame(width: geometry.size.width * progress, height: height)
                }
            }
            .frame(height: height)
            
            if showLabel {
                Text("\(Int(progress * 100))%")
                    .font(WKTypography.captionMedium)
                    .foregroundStyle(WKColor.textSecondary)
            }
        }
    }
}

// MARK: - WKSessionProgress

/// A session progress indicator for reviews/lessons showing current position.
public struct WKSessionProgress: View {
    let current: Int
    let total: Int
    let color: Color
    
    public init(current: Int, total: Int, color: Color = .accentColor) {
        self.current = current
        self.total = total
        self.color = color
    }
    
    public var body: some View {
        HStack(spacing: WKSpacing.sm) {
            WKProgressBar(
                progress: total > 0 ? Double(current) / Double(total) : 0,
                color: color,
                height: 4
            )
            
            Text("\(current)/\(total)")
                .font(WKTypography.captionMedium)
                .foregroundStyle(WKColor.textSecondary)
                .monospacedDigit()
        }
    }
}

// MARK: - WKSkeletonView

/// A shimmer placeholder for loading states.
public struct WKSkeletonView: View {
    let width: CGFloat?
    let height: CGFloat
    
    @State private var isAnimating = false
    
    public init(width: CGFloat? = nil, height: CGFloat = 20) {
        self.width = width
        self.height = height
    }
    
    public var body: some View {
        RoundedRectangle(cornerRadius: WKRadius.xs)
            .fill(WKColor.surfaceTertiary)
            .frame(width: width, height: height)
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            WKColor.surfaceSecondary.opacity(0.5),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.5)
                    .offset(x: isAnimating ? geometry.size.width : -geometry.size.width * 0.5)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: WKRadius.xs))
            .onAppear {
                withAnimation(
                    .linear(duration: 1.2)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - WKSkeletonCard

/// A skeleton placeholder for card-shaped content.
public struct WKSkeletonCard: View {
    public init() {}
    
    public var body: some View {
        WKCard {
            VStack(alignment: .leading, spacing: WKSpacing.sm) {
                WKSkeletonView(width: 100, height: 14)
                WKSkeletonView(height: 24)
                WKSkeletonView(width: 150, height: 14)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: WKSpacing.lg) {
            WKLoadingView("Loading reviews...")
                .frame(height: 150)
            
            VStack(alignment: .leading, spacing: WKSpacing.md) {
                Text("Progress Bars")
                    .font(WKTypography.titleSmall)
                
                WKProgressBar(progress: 0.3, color: WKColor.radical)
                WKProgressBar(progress: 0.6, color: WKColor.kanji, showLabel: true)
                WKProgressBar(progress: 0.9, color: WKColor.success)
            }
            
            VStack(alignment: .leading, spacing: WKSpacing.md) {
                Text("Session Progress")
                    .font(WKTypography.titleSmall)
                
                WKSessionProgress(current: 12, total: 50, color: WKColor.radical)
            }
            
            VStack(alignment: .leading, spacing: WKSpacing.md) {
                Text("Skeleton Loading")
                    .font(WKTypography.titleSmall)
                
                WKSkeletonCard()
                
                HStack(spacing: WKSpacing.sm) {
                    WKSkeletonView(width: 60, height: 60)
                    VStack(alignment: .leading, spacing: WKSpacing.xs) {
                        WKSkeletonView(width: 120, height: 16)
                        WKSkeletonView(width: 80, height: 14)
                    }
                }
            }
        }
        .padding()
    }
}

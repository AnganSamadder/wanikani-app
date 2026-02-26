import SwiftUI

// MARK: - WKStatTile

/// A tile component for displaying statistics with consistent styling.
public struct WKStatTile: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String?
    let color: Color
    let style: Style
    
    public enum Style {
        case standard
        case prominent
        case compact
    }
    
    public init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String? = nil,
        color: Color = .accentColor,
        style: Style = .standard
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.style = style
    }
    
    public var body: some View {
        switch style {
        case .standard:
            standardLayout
        case .prominent:
            prominentLayout
        case .compact:
            compactLayout
        }
    }
    
    private var standardLayout: some View {
        WKCard {
            VStack(alignment: .leading, spacing: WKSpacing.xs) {
                HStack(spacing: WKSpacing.xs) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(WKTypography.caption)
                            .foregroundStyle(color)
                    }
                    Text(title)
                        .font(WKTypography.captionMedium)
                        .foregroundStyle(WKColor.textSecondary)
                }
                
                Text(value)
                    .font(WKTypography.title)
                    .foregroundStyle(WKColor.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(WKTypography.caption)
                        .foregroundStyle(WKColor.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var prominentLayout: some View {
        VStack(spacing: WKSpacing.xs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(color)
            }
            
            Text(value)
                .font(WKTypography.display)
                .foregroundStyle(.white)
            
            Text(title)
                .font(WKTypography.bodyMedium)
                .foregroundStyle(.white.opacity(0.85))
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(WKTypography.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, WKSpacing.lg)
        .padding(.horizontal, WKSpacing.md)
        .background(color.gradient)
        .clipShape(RoundedRectangle(cornerRadius: WKRadius.lg, style: .continuous))
    }
    
    private var compactLayout: some View {
        HStack(spacing: WKSpacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(WKTypography.body)
                    .foregroundStyle(color)
                    .frame(width: 24)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(WKTypography.caption)
                    .foregroundStyle(WKColor.textSecondary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(WKTypography.caption)
                        .foregroundStyle(WKColor.textTertiary)
                }
            }
            
            Spacer()
            
            Text(value)
                .font(WKTypography.titleSmall)
                .foregroundStyle(WKColor.textPrimary)
        }
        .padding(.vertical, WKSpacing.xs)
    }
}

// MARK: - Review/Lesson Action Tile

/// A prominent action tile for starting reviews or lessons
public struct WKActionTile: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    public init(
        title: String,
        count: Int,
        color: Color,
        icon: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.count = count
        self.color = color
        self.icon = icon
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: WKSpacing.xxs) {
                    Text(title)
                        .font(WKTypography.bodyMedium)
                        .foregroundStyle(.white.opacity(0.9))
                    
                    Text("\(count)")
                        .font(WKTypography.display)
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(WKSpacing.lg)
            .background(color.gradient)
            .clipShape(RoundedRectangle(cornerRadius: WKRadius.lg, style: .continuous))
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(WKAnimation.quick) { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation(WKAnimation.quick) { isPressed = false }
                }
        )
        .accessibilityLabel("\(title): \(count) available")
    }
}

#Preview {
    ScrollView {
        VStack(spacing: WKSpacing.md) {
            WKStatTile(
                title: "Accuracy",
                value: "94.2%",
                subtitle: "Last 30 days",
                icon: "chart.line.uptrend.xyaxis",
                color: WKColor.success
            )
            
            HStack(spacing: WKSpacing.sm) {
                WKStatTile(
                    title: "Level",
                    value: "12",
                    icon: "star.fill",
                    color: WKColor.kanji,
                    style: .prominent
                )
                
                WKStatTile(
                    title: "Streak",
                    value: "7",
                    subtitle: "days",
                    icon: "flame.fill",
                    color: .orange,
                    style: .prominent
                )
            }
            
            WKActionTile(
                title: "Reviews",
                count: 42,
                color: WKColor.radical,
                icon: "arrow.right.circle.fill"
            ) { }
            
            WKActionTile(
                title: "Lessons",
                count: 15,
                color: WKColor.kanji,
                icon: "book.fill"
            ) { }
        }
        .padding()
    }
}

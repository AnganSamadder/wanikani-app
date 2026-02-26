import SwiftUI

// MARK: - WKEmptyState

/// A unified component for empty, error, and offline states.
public struct WKEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    let style: Style
    
    public enum Style {
        case empty
        case error
        case offline
        case success
    }
    
    public init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil,
        style: Style = .empty
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
        self.style = style
    }
    
    public var body: some View {
        VStack(spacing: WKSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(iconColor)
            
            VStack(spacing: WKSpacing.xs) {
                Text(title)
                    .font(WKTypography.titleMedium)
                    .foregroundStyle(WKColor.textPrimary)
                
                Text(message)
                    .font(WKTypography.body)
                    .foregroundStyle(WKColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                WKButton(actionTitle, style: buttonStyle, action: action)
                    .padding(.top, WKSpacing.xs)
            }
        }
        .padding(WKSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var iconColor: Color {
        switch style {
        case .empty:
            return WKColor.textTertiary
        case .error:
            return WKColor.error
        case .offline:
            return WKColor.warning
        case .success:
            return WKColor.success
        }
    }
    
    private var buttonStyle: WKButtonStyle {
        switch style {
        case .error:
            return .primary
        case .offline:
            return .secondary
        default:
            return .tertiary
        }
    }
}

// MARK: - Convenience Initializers

extension WKEmptyState {
    /// Empty state for "all caught up" scenarios
    public static func allCaughtUp(
        title: String = "All Caught Up!",
        message: String = "You've completed everything for now."
    ) -> WKEmptyState {
        WKEmptyState(
            icon: "checkmark.circle.fill",
            title: title,
            message: message,
            style: .success
        )
    }
    
    /// Empty state for no content
    public static func noContent(
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) -> WKEmptyState {
        WKEmptyState(
            icon: "tray",
            title: title,
            message: message,
            actionTitle: actionTitle,
            action: action,
            style: .empty
        )
    }
    
    /// Error state with retry
    public static func error(
        title: String = "Something Went Wrong",
        message: String,
        onRetry: @escaping () -> Void
    ) -> WKEmptyState {
        WKEmptyState(
            icon: "exclamationmark.triangle.fill",
            title: title,
            message: message,
            actionTitle: "Try Again",
            action: onRetry,
            style: .error
        )
    }
    
    /// Offline state
    public static func offline(
        message: String = "Check your internet connection and try again.",
        onRetry: @escaping () -> Void
    ) -> WKEmptyState {
        WKEmptyState(
            icon: "wifi.slash",
            title: "You're Offline",
            message: message,
            actionTitle: "Retry",
            action: onRetry,
            style: .offline
        )
    }
}

#Preview {
    TabView {
        WKEmptyState.allCaughtUp()
            .tabItem { Text("Success") }
        
        WKEmptyState.noContent(
            title: "No Lessons",
            message: "Check back later for new content.",
            actionTitle: "Refresh"
        ) { }
            .tabItem { Text("Empty") }
        
        WKEmptyState.error(
            message: "Failed to load your review queue."
        ) { }
            .tabItem { Text("Error") }
        
        WKEmptyState.offline { }
            .tabItem { Text("Offline") }
    }
}

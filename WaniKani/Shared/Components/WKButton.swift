import SwiftUI

// MARK: - WKButton Style

public enum WKButtonStyle {
    case primary
    case secondary
    case tertiary
    case destructive
}

public enum WKButtonSize {
    case small
    case medium
    case large
    
    var verticalPadding: CGFloat {
        switch self {
        case .small: return WKSpacing.xs
        case .medium: return WKSpacing.sm
        case .large: return WKSpacing.md
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return WKSpacing.sm
        case .medium: return WKSpacing.md
        case .large: return WKSpacing.lg
        }
    }
    
    var font: Font {
        switch self {
        case .small: return WKTypography.captionMedium
        case .medium: return WKTypography.bodyMedium
        case .large: return WKTypography.titleSmall
        }
    }
}

// MARK: - WKButton

public struct WKButton: View {
    let title: String
    let icon: String?
    let style: WKButtonStyle
    let size: WKButtonSize
    let isFullWidth: Bool
    let isLoading: Bool
    let action: () -> Void
    
    @Environment(\.isEnabled) private var isEnabled
    
    public init(
        _ title: String,
        icon: String? = nil,
        style: WKButtonStyle = .primary,
        size: WKButtonSize = .medium,
        isFullWidth: Bool = false,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.isFullWidth = isFullWidth
        self.isLoading = isLoading
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: WKSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(size.font)
                }
                
                Text(title)
                    .font(size.font)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: WKRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: WKRadius.md, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: style == .secondary ? 1.5 : 0)
            )
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1.0 : 0.5)
        .allowsHitTesting(!isLoading)
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return WKColor.textPrimary
        case .tertiary:
            return .accentColor
        case .destructive:
            return .white
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return .accentColor
        case .secondary:
            return .clear
        case .tertiary:
            return .accentColor.opacity(0.12)
        case .destructive:
            return WKColor.error
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .secondary:
            return WKColor.border
        default:
            return .clear
        }
    }
}

// MARK: - Subject-Colored Button

extension WKButton {
    /// Creates a button with subject type coloring
    public static func forSubject(
        _ title: String,
        type: String,
        size: WKButtonSize = .medium,
        isFullWidth: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(size.font)
                .fontWeight(.semibold)
                .padding(.horizontal, size.horizontalPadding)
                .padding(.vertical, size.verticalPadding)
                .frame(maxWidth: isFullWidth ? .infinity : nil)
                .foregroundStyle(.white)
                .background(WKColor.forSubjectType(type))
                .clipShape(RoundedRectangle(cornerRadius: WKRadius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: WKSpacing.md) {
        WKButton("Primary Button", icon: "arrow.right", style: .primary, size: .large, isFullWidth: true) { }
        WKButton("Secondary", style: .secondary) { }
        WKButton("Tertiary", style: .tertiary) { }
        WKButton("Delete", icon: "trash", style: .destructive) { }
        WKButton("Loading...", style: .primary, isLoading: true) { }
        
        HStack(spacing: WKSpacing.sm) {
            WKButton.forSubject("Radical", type: "radical") { }
            WKButton.forSubject("Kanji", type: "kanji") { }
            WKButton.forSubject("Vocab", type: "vocabulary") { }
        }
    }
    .padding()
}

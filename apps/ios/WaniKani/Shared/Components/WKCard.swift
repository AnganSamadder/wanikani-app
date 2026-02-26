import SwiftUI

// MARK: - WKCard

/// A consistent card surface component for content grouping.
/// Uses subtle border rather than heavy shadows for a clean look.
public struct WKCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let content: Content
    let padding: CGFloat
    let isElevated: Bool
    
    public init(
        padding: CGFloat = WKSpacing.md,
        isElevated: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.isElevated = isElevated
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(padding)
            .background(WKColor.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: WKRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: WKRadius.md, style: .continuous)
                    .strokeBorder(WKColor.border, lineWidth: 0.5)
            )
            .shadow(
                color: isElevated ? Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08) : .clear,
                radius: isElevated ? WKShadow.subtleRadius : 0,
                x: 0,
                y: isElevated ? WKShadow.subtleY : 0
            )
    }
}

// MARK: - WKCard Variants

extension WKCard {
    /// Card with subject type accent
    public func accent(for subjectType: String) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: WKRadius.md, style: .continuous)
                .strokeBorder(WKColor.forSubjectType(subjectType), lineWidth: 2)
        )
    }
}

// MARK: - Convenience Modifiers

extension View {
    /// Apply card styling to any view
    public func wkCardStyle(padding: CGFloat = WKSpacing.md, isElevated: Bool = false) -> some View {
        WKCard(padding: padding, isElevated: isElevated) { self }
    }
}

#Preview {
    VStack(spacing: WKSpacing.md) {
        WKCard {
            VStack(alignment: .leading, spacing: WKSpacing.xs) {
                Text("Standard Card")
                    .font(WKTypography.titleSmall)
                Text("A clean surface for content grouping")
                    .font(WKTypography.body)
                    .foregroundStyle(WKColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        
        WKCard(isElevated: true) {
            Text("Elevated Card")
                .font(WKTypography.body)
                .frame(maxWidth: .infinity)
        }
    }
    .padding()
}

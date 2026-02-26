import SwiftUI

enum AppTheme {
    static var spacing: CGFloat {
        CoreTheme.spacing
    }

    static var screenPadding: CGFloat {
        CoreTheme.screenPadding
    }

    static var cardRadius: CGFloat {
        CoreTheme.cardRadius
    }

    static var strokeWidth: CGFloat {
        CoreTheme.strokeWidth
    }

    static var topGradient: LinearGradient {
        CoreTheme.topGradient
    }

    static func screenBackground(for scheme: ColorScheme) -> Color {
        CoreTheme.screenBackground(for: scheme)
    }

    static func cardBackground(for scheme: ColorScheme) -> Color {
        CoreTheme.cardBackground(for: scheme)
    }

    static func cardBorder(for scheme: ColorScheme) -> Color {
        CoreTheme.cardBorder(for: scheme)
    }

    static func primaryText(for scheme: ColorScheme) -> Color {
        CoreTheme.primaryText(for: scheme)
    }

    static func secondaryText(for scheme: ColorScheme) -> Color {
        CoreTheme.secondaryText(for: scheme)
    }

    static var accent: Color {
        WKColor.kanji
    }
}

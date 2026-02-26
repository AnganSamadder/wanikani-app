import SwiftUI

enum CoreTheme {
    static let cardRadius: CGFloat = 8
    static let spacing: CGFloat = 12
    static let screenPadding: CGFloat = 16
    static let strokeWidth: CGFloat = 1
    static let topGradient = LinearGradient(
        colors: [
            Color(red: 0.72, green: 0.05, blue: 0.96),
            Color(red: 0.54, green: 0.03, blue: 0.88)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func screenBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.08, green: 0.08, blue: 0.10) : Color(red: 0.96, green: 0.96, blue: 0.97)
    }

    static func cardBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.15, green: 0.15, blue: 0.18) : .white
    }

    static func cardBorder(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.16) : Color.black.opacity(0.08)
    }

    static func primaryText(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.94, green: 0.94, blue: 0.97) : Color(red: 0.10, green: 0.10, blue: 0.12)
    }

    static func secondaryText(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.74, green: 0.74, blue: 0.79) : Color(red: 0.40, green: 0.40, blue: 0.44)
    }
}

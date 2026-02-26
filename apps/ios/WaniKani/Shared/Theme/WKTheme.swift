import SwiftUI

// MARK: - WaniKani Design System
// A cohesive theme inspired by WaniKani's brand while maintaining iOS-native feel

// MARK: - Color Tokens

public enum WKColor {
    // MARK: - Brand Colors (Semantic Accents)
    
    /// Radical - Blue tones
    public static let radical = Color(red: 0.00, green: 0.67, blue: 0.89) // #00AACC
    public static let radicalBackground = Color(red: 0.00, green: 0.67, blue: 0.89).opacity(0.12)
    
    /// Kanji - Pink/Magenta tones
    public static let kanji = Color(red: 0.91, green: 0.12, blue: 0.39) // #E91E63
    public static let kanjiBackground = Color(red: 0.91, green: 0.12, blue: 0.39).opacity(0.12)
    
    /// Vocabulary - Purple tones
    public static let vocabulary = Color(red: 0.66, green: 0.31, blue: 0.78) // #A855C8
    public static let vocabularyBackground = Color(red: 0.66, green: 0.31, blue: 0.78).opacity(0.12)
    
    // MARK: - Semantic Colors
    
    public static let success = Color(red: 0.20, green: 0.78, blue: 0.35) // #34C759
    public static let warning = Color(red: 1.00, green: 0.80, blue: 0.00) // #FFCC00
    public static let error = Color(red: 1.00, green: 0.27, blue: 0.23) // #FF453A
    
    // MARK: - Surface Colors (Adaptive)
    
    public static let surfacePrimary = Color(.systemBackground)
    public static let surfaceSecondary = Color(.secondarySystemBackground)
    public static let surfaceTertiary = Color(.tertiarySystemBackground)
    public static let surfaceGrouped = Color(.systemGroupedBackground)
    
    // MARK: - Text Colors (Adaptive)
    
    public static let textPrimary = Color(.label)
    public static let textSecondary = Color(.secondaryLabel)
    public static let textTertiary = Color(.tertiaryLabel)
    public static let textPlaceholder = Color(.placeholderText)
    
    // MARK: - Border & Separator
    
    public static let separator = Color(.separator)
    public static let border = Color(.separator).opacity(0.5)
    
    // MARK: - Helpers
    
    /// Returns the appropriate color for a subject type
    public static func forSubjectType(_ type: String) -> Color {
        switch type.lowercased() {
        case "radical": return radical
        case "kanji": return kanji
        case "vocabulary", "kana_vocabulary": return vocabulary
        default: return textSecondary
        }
    }
    
    /// Returns the appropriate background color for a subject type
    public static func backgroundForSubjectType(_ type: String) -> Color {
        switch type.lowercased() {
        case "radical": return radicalBackground
        case "kanji": return kanjiBackground
        case "vocabulary", "kana_vocabulary": return vocabularyBackground
        default: return surfaceSecondary
        }
    }
}

// MARK: - Typography Tokens

public enum WKTypography {
    // MARK: - Display (Large headers)
    
    public static let displayLarge = Font.system(size: 56, weight: .bold, design: .rounded)
    public static let display = Font.system(size: 40, weight: .bold, design: .rounded)
    
    // MARK: - Titles
    
    public static let title = Font.system(size: 28, weight: .bold, design: .default)
    public static let titleMedium = Font.system(size: 22, weight: .semibold, design: .default)
    public static let titleSmall = Font.system(size: 17, weight: .semibold, design: .default)
    
    // MARK: - Body
    
    public static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    public static let body = Font.system(size: 15, weight: .regular, design: .default)
    public static let bodyMedium = Font.system(size: 14, weight: .medium, design: .default)
    
    // MARK: - Caption
    
    public static let caption = Font.system(size: 12, weight: .regular, design: .default)
    public static let captionMedium = Font.system(size: 12, weight: .medium, design: .default)
    
    // MARK: - Japanese Text
    
    public static let japanese = Font.system(size: 64, weight: .regular, design: .default)
    public static let japaneseLarge = Font.system(size: 80, weight: .regular, design: .default)
    public static let japaneseReading = Font.system(size: 24, weight: .regular, design: .default)
    
    // MARK: - Monospaced (for readings if desired)
    
    public static let mono = Font.system(size: 15, weight: .regular, design: .monospaced)
    public static let monoSmall = Font.system(size: 13, weight: .regular, design: .monospaced)
}

// MARK: - Spacing Tokens

public enum WKSpacing {
    /// 4pt - Minimal spacing
    public static let xxs: CGFloat = 4
    
    /// 8pt - Tight spacing
    public static let xs: CGFloat = 8
    
    /// 12pt - Compact spacing
    public static let sm: CGFloat = 12
    
    /// 16pt - Standard spacing
    public static let md: CGFloat = 16
    
    /// 20pt - Comfortable spacing
    public static let lg: CGFloat = 20
    
    /// 24pt - Relaxed spacing
    public static let xl: CGFloat = 24
    
    /// 32pt - Section spacing
    public static let xxl: CGFloat = 32
    
    /// 48pt - Large section spacing
    public static let xxxl: CGFloat = 48
}

// MARK: - Corner Radius Tokens

public enum WKRadius {
    /// 4pt - Subtle rounding
    public static let xs: CGFloat = 4
    
    /// 8pt - Small components
    public static let sm: CGFloat = 8
    
    /// 12pt - Cards and containers
    public static let md: CGFloat = 12
    
    /// 16pt - Large cards
    public static let lg: CGFloat = 16
    
    /// 24pt - Modal/sheet corners
    public static let xl: CGFloat = 24
    
    /// Full circle
    public static let full: CGFloat = 9999
}

// MARK: - Animation Tokens

public enum WKAnimation {
    /// Quick interactions (button taps)
    public static let quick = Animation.easeOut(duration: 0.15)
    
    /// Standard transitions
    public static let standard = Animation.easeInOut(duration: 0.25)
    
    /// Smooth, noticeable transitions
    public static let smooth = Animation.easeInOut(duration: 0.35)
    
    /// Spring for bouncy feedback
    public static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)
    
    /// Gentle spring for subtle bounces
    public static let gentleSpring = Animation.spring(response: 0.4, dampingFraction: 0.8)
}

// MARK: - Shadow Tokens

public enum WKShadow {
    /// Subtle elevation (cards)
    public static func subtle(_ colorScheme: ColorScheme) -> some View {
        Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08)
    }
    
    public static let subtleRadius: CGFloat = 8
    public static let subtleY: CGFloat = 2
}

import SwiftUI

// MARK: - WKBadge

/// A badge component for displaying categories, counts, or status indicators.
public struct WKBadge: View {
    public enum Style {
        case filled
        case outlined
        case subtle
    }
    
    let text: String
    let color: Color
    let style: Style
    
    public init(_ text: String, color: Color = .accentColor, style: Style = .filled) {
        self.text = text
        self.color = color
        self.style = style
    }
    
    public var body: some View {
        Text(text)
            .font(WKTypography.captionMedium)
            .padding(.horizontal, WKSpacing.xs)
            .padding(.vertical, WKSpacing.xxs)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: WKRadius.xs, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: WKRadius.xs, style: .continuous)
                    .strokeBorder(style == .outlined ? color : .clear, lineWidth: 1)
            )
    }
    
    private var foregroundColor: Color {
        switch style {
        case .filled:
            return .white
        case .outlined:
            return color
        case .subtle:
            return color
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .filled:
            return color
        case .outlined:
            return .clear
        case .subtle:
            return color.opacity(0.12)
        }
    }
}

// MARK: - Subject Badge

extension WKBadge {
    /// Creates a badge for a subject type
    public static func subject(_ type: String) -> WKBadge {
        let displayName: String
        switch type.lowercased() {
        case "radical": displayName = "Radical"
        case "kanji": displayName = "Kanji"
        case "vocabulary": displayName = "Vocabulary"
        case "kana_vocabulary": displayName = "Kana"
        default: displayName = type.capitalized
        }
        return WKBadge(displayName, color: WKColor.forSubjectType(type), style: .filled)
    }
}

// MARK: - SRS Stage Badge

extension WKBadge {
    /// Creates a badge for an SRS stage
    public static func srsStage(_ stage: Int) -> WKBadge {
        let (name, color) = srsInfo(for: stage)
        return WKBadge(name, color: color, style: .subtle)
    }
    
    private static func srsInfo(for stage: Int) -> (String, Color) {
        switch stage {
        case 0: return ("Lesson", WKColor.textTertiary)
        case 1: return ("Apprentice 1", Color.orange.opacity(0.8))
        case 2: return ("Apprentice 2", Color.orange.opacity(0.9))
        case 3: return ("Apprentice 3", Color.orange)
        case 4: return ("Apprentice 4", Color.orange)
        case 5: return ("Guru 1", WKColor.kanji.opacity(0.8))
        case 6: return ("Guru 2", WKColor.kanji)
        case 7: return ("Master", WKColor.radical)
        case 8: return ("Enlightened", WKColor.vocabulary)
        case 9: return ("Burned", WKColor.textSecondary)
        default: return ("Unknown", WKColor.textTertiary)
        }
    }
}

// MARK: - Count Badge

/// A numeric badge for displaying counts
public struct WKCountBadge: View {
    let count: Int
    let color: Color
    let size: CGFloat
    
    public init(_ count: Int, color: Color = .accentColor, size: CGFloat = 24) {
        self.count = count
        self.color = color
        self.size = size
    }
    
    public var body: some View {
        Text("\(count)")
            .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(minWidth: size, minHeight: size)
            .padding(.horizontal, count > 99 ? WKSpacing.xxs : 0)
            .background(color)
            .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: WKSpacing.lg) {
        HStack(spacing: WKSpacing.sm) {
            WKBadge("New", color: WKColor.success)
            WKBadge("Pending", color: WKColor.warning, style: .outlined)
            WKBadge("Info", color: .accentColor, style: .subtle)
        }
        
        HStack(spacing: WKSpacing.sm) {
            WKBadge.subject("radical")
            WKBadge.subject("kanji")
            WKBadge.subject("vocabulary")
        }
        
        HStack(spacing: WKSpacing.sm) {
            WKBadge.srsStage(1)
            WKBadge.srsStage(5)
            WKBadge.srsStage(8)
        }
        
        HStack(spacing: WKSpacing.sm) {
            WKCountBadge(5, color: WKColor.radical)
            WKCountBadge(42, color: WKColor.kanji)
            WKCountBadge(128, color: WKColor.vocabulary)
        }
    }
    .padding()
}

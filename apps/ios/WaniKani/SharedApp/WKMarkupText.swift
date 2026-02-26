import SwiftUI

struct WKMarkupText: View {
    let text: String
    var font: Font = .body

    var body: some View {
        Text(renderedText)
            .font(font)
    }

    private var renderedText: AttributedString {
        guard let regex = try? NSRegularExpression(pattern: #"<(radical|kanji|vocabulary|meaning|reading)>(.*?)</\1>"#, options: [.dotMatchesLineSeparators]) else {
            return AttributedString(text)
        }

        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        let matches = regex.matches(in: text, options: [], range: fullRange)
        if matches.isEmpty {
            return AttributedString(text)
        }

        var composed = AttributedString()
        var cursor = 0

        for match in matches {
            let matchRange = match.range(at: 0)
            if matchRange.location > cursor {
                let prefix = nsText.substring(with: NSRange(location: cursor, length: matchRange.location - cursor))
                composed.append(AttributedString(prefix))
            }

            guard match.numberOfRanges >= 3 else {
                cursor = matchRange.location + matchRange.length
                continue
            }

            let tag = nsText.substring(with: match.range(at: 1))
            let value = nsText.substring(with: match.range(at: 2))
            var highlighted = AttributedString(value)
            highlighted.foregroundColor = highlightColor(for: tag)
            highlighted.backgroundColor = highlightColor(for: tag).opacity(0.16)
            composed.append(highlighted)
            cursor = matchRange.location + matchRange.length
        }

        if cursor < nsText.length {
            composed.append(AttributedString(nsText.substring(from: cursor)))
        }

        return composed
    }

    private func highlightColor(for tag: String) -> Color {
        switch tag {
        case "radical": return WKColor.radical
        case "kanji": return WKColor.kanji
        case "vocabulary": return WKColor.vocabulary
        case "meaning": return .primary
        case "reading": return .secondary
        default: return .primary
        }
    }
}

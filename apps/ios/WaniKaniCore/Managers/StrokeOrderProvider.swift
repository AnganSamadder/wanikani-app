import Foundation

/// Fetches and caches KanjiVG stroke order SVGs for individual characters.
/// Returns nil gracefully for characters without a KanjiVG entry.
public actor StrokeOrderProvider {
    private let cacheDirectory: URL

    public init() {
        cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

    public func strokeOrderSVG(for character: Character) async throws -> String? {
        guard let scalar = character.unicodeScalars.first else { return nil }
        let hex = String(format: "%04x", scalar.value)
        let cacheURL = cacheDirectory.appendingPathComponent("kanjivg_\(hex).svg")

        // Check disk cache first
        if let cached = try? String(contentsOf: cacheURL, encoding: .utf8) {
            return cached
        }

        // Fetch from KanjiVG GitHub raw content
        let urlString = "https://raw.githubusercontent.com/KanjiVG/kanjivg/master/kanji/0x\(hex).svg"
        guard let url = URL(string: urlString) else { return nil }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let svgString = String(data: data, encoding: .utf8) else {
            return nil
        }

        // Cache to disk
        try? svgString.write(to: cacheURL, atomically: true, encoding: .utf8)
        return svgString
    }
}

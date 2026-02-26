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
        let hex = kanjiVGHex(for: scalar.value)
        let cacheURL = cacheDirectory.appendingPathComponent("kanjivg_\(hex).svg")

        // Check disk cache first
        if let cached = try? String(contentsOf: cacheURL, encoding: .utf8) {
            return cached
        }

        // Fetch from KanjiVG with CDN fallback for better reliability.
        for url in candidateURLs(for: hex) {
            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 10
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200,
                      let svgString = String(data: data, encoding: .utf8) else {
                    continue
                }

                // Cache to disk
                try? svgString.write(to: cacheURL, atomically: true, encoding: .utf8)
                return svgString
            } catch {
                continue
            }
        }
        return nil
    }

    private func kanjiVGHex(for scalarValue: UInt32) -> String {
        let raw = String(scalarValue, radix: 16, uppercase: false)
        // KanjiVG uses zero-padded lower-case filenames, e.g. "07cf8.svg".
        return raw.count >= 5 ? raw : String(repeating: "0", count: 5 - raw.count) + raw
    }

    private func candidateURLs(for hex: String) -> [URL] {
        [
            URL(string: "https://raw.githubusercontent.com/KanjiVG/kanjivg/master/kanji/\(hex).svg"),
            URL(string: "https://cdn.jsdelivr.net/gh/KanjiVG/kanjivg/kanji/\(hex).svg"),
            URL(string: "https://kanjivg.tagaini.net/kanjivg/kanji/\(hex).svg")
        ].compactMap { $0 }
    }
}

import Foundation

public struct PitchPattern: Sendable, Hashable {
    public let pattern: String
    public let moraCount: Int

    public init(pattern: String, moraCount: Int) {
        self.pattern = pattern
        self.moraCount = moraCount
    }
}

/// Provides pitch accent patterns from a bundled Kanjium TSV resource.
/// Falls back gracefully if the resource is not present.
public actor PitchAccentProvider {
    private var cache: [String: [PitchPattern]] = [:]
    private var isLoaded = false

    public init() {}

    private func load() {
        guard !isLoaded else { return }
        isLoaded = true

        guard let url = Bundle.main.url(forResource: "Kanjium_accents", withExtension: "tsv"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return
        }

        for line in content.components(separatedBy: .newlines) {
            let parts = line.components(separatedBy: "\t")
            guard parts.count >= 3 else { continue }
            let kanji = parts[0]
            let reading = parts[1]
            let pattern = parts[2].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !pattern.isEmpty else { continue }
            let key = "\(kanji):\(reading)"
            let moraCount = reading.count
            let pitchPattern = PitchPattern(pattern: pattern, moraCount: moraCount)
            cache[key, default: []].append(pitchPattern)
        }
    }

    public func patterns(for characters: String, reading: String) -> [PitchPattern] {
        load()
        let key = "\(characters):\(reading)"
        return cache[key] ?? []
    }
}

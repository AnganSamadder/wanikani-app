import Foundation

public struct PitchPattern: Sendable, Hashable {
    public let pattern: String
    public let moraCount: Int

    public init(pattern: String, moraCount: Int) {
        self.pattern = pattern
        self.moraCount = moraCount
    }
}

/// Provides pitch accent patterns with a JPDict-first strategy and Kanjium fallback.
///
/// Loading order:
/// 1. In-memory dictionary
/// 2. Local app-support JPDict compact cache (binary plist)
/// 3. Local app-support Kanjium compact cache (binary plist)
/// 4. Remote JPDict word data
/// 5. Remote Kanjium accents fallback
public actor PitchAccentProvider {
    private var cache: [String: [PitchPattern]] = [:] // key format: "\(surface):\(readingHiragana)"
    private var isLoaded = false
    private var lastJPDictLoadAttempt: Date?
    private var lastKanjiumLoadAttempt: Date?

    private let remoteJPDictURL = URL(
        string: "https://raw.githubusercontent.com/birchill/%31%30%74%65%6E-ja-reader/main/data/words.ljson"
    )
    private let remoteKanjiumURL = URL(string: "https://raw.githubusercontent.com/mifunetoshiro/kanjium/master/accents.txt")
    private let jpdictCacheFileName = "jpdict_pitch_cache.plist"
    private let kanjiumCacheFileName = "kanjium_pitch_cache.plist"
    private let remoteLoadRetryInterval: TimeInterval = 30 * 60

    public init() {}

    private func loadIfNeeded() async {
        guard !isLoaded else { return }
        if loadFromCompactCache(fileName: jpdictCacheFileName) ||
            loadFromCompactCache(fileName: kanjiumCacheFileName) {
            isLoaded = true
            return
        }

        if !shouldBackOffJPDictLoad() {
            lastJPDictLoadAttempt = Date()
            if await buildFromJPDictSource() {
                isLoaded = true
                return
            }
        }

        if !shouldBackOffKanjiumLoad() {
            lastKanjiumLoadAttempt = Date()
            if await buildFromKanjiumSource() {
                isLoaded = true
                return
            }
        }

        if loadFromCompactCache(fileName: kanjiumCacheFileName) {
            isLoaded = true
        }
    }

    private func shouldBackOffJPDictLoad(now: Date = Date()) -> Bool {
        guard let lastJPDictLoadAttempt else {
            return false
        }
        return now.timeIntervalSince(lastJPDictLoadAttempt) < remoteLoadRetryInterval
    }

    private func shouldBackOffKanjiumLoad(now: Date = Date()) -> Bool {
        guard let lastKanjiumLoadAttempt else {
            return false
        }
        return now.timeIntervalSince(lastKanjiumLoadAttempt) < remoteLoadRetryInterval
    }

    private func loadFromCompactCache(fileName: String) -> Bool {
        guard let cacheURL = localCacheURL(fileName: fileName),
              let data = try? Data(contentsOf: cacheURL),
              let propertyList = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let compact = propertyList as? [String: [Int]] else {
            return false
        }

        cache = buildPatterns(from: compact)
        return true
    }

    private func buildFromJPDictSource() async -> Bool {
        guard let remoteJPDictURL else { return false }
        var request = URLRequest(url: remoteJPDictURL)
        request.timeoutInterval = 30

        guard let (bytes, response) = try? await URLSession.shared.bytes(for: request),
              let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            return false
        }

        var compact: [String: Set<Int>] = [:]
        do {
            // Stream line-by-line to avoid loading the full dataset into memory.
            for try await line in bytes.lines {
                extractJPDictPitchEntries(from: line, into: &compact)
            }
        } catch {
            return false
        }

        let finalCompact: [String: [Int]] = compact.mapValues { Array($0).sorted() }
        cache = buildPatterns(from: finalCompact)

        if let cacheURL = localCacheURL(fileName: jpdictCacheFileName),
           let plistData = try? PropertyListSerialization.data(fromPropertyList: finalCompact, format: .binary, options: 0) {
            try? ensureCacheDirectoryExists()
            try? plistData.write(to: cacheURL, options: .atomic)
        }
        return true
    }

    private func buildFromKanjiumSource() async -> Bool {
        guard let remoteKanjiumURL else { return false }
        var request = URLRequest(url: remoteKanjiumURL)
        request.timeoutInterval = 30

        guard let (bytes, response) = try? await URLSession.shared.bytes(for: request),
              let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            return false
        }

        var compact: [String: Set<Int>] = [:]
        do {
            for try await line in bytes.lines {
                extractKanjiumPitchEntries(from: line, into: &compact)
            }
        } catch {
            return false
        }

        let finalCompact: [String: [Int]] = compact.mapValues { Array($0).sorted() }
        cache = buildPatterns(from: finalCompact)

        if let cacheURL = localCacheURL(fileName: kanjiumCacheFileName),
           let plistData = try? PropertyListSerialization.data(fromPropertyList: finalCompact, format: .binary, options: 0) {
            try? ensureCacheDirectoryExists()
            try? plistData.write(to: cacheURL, options: .atomic)
        }
        return true
    }

    private func extractJPDictPitchEntries(from line: String, into compact: inout [String: Set<Int>]) {
        guard let record = decodeJPDictRecord(from: line) else { return }
        guard !record.r.isEmpty else { return }

        let surfaceForms = (record.k?.isEmpty == false) ? record.k! : []
        for (index, readingRaw) in record.r.enumerated() {
            let reading = normalizeReading(readingRaw)
            guard !reading.isEmpty else { continue }
            let accents = accentsForJPDictReading(at: index, in: record)
            guard !accents.isEmpty else { continue }

            let wildcardKey = "*:\(reading)"
            compact[wildcardKey, default: []].formUnion(accents)

            for surface in surfaceForms {
                let key = "\(surface):\(reading)"
                compact[key, default: []].formUnion(accents)
            }
        }
    }

    private func extractKanjiumPitchEntries(from line: String, into compact: inout [String: Set<Int>]) {
        let parts = line.split(separator: "\t", omittingEmptySubsequences: false)
        guard parts.count >= 3 else { return }

        let surface = String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
        let reading = normalizeReading(String(parts[1]))
        let accents = parseAccents(String(parts[2]))

        guard !reading.isEmpty, !accents.isEmpty else { return }

        let wildcardKey = "*:\(reading)"
        compact[wildcardKey, default: []].formUnion(accents)

        if !surface.isEmpty {
            let key = "\(surface):\(reading)"
            compact[key, default: []].formUnion(accents)
        }
    }

    private func decodeJPDictRecord(from line: String) -> JPDictWordRecord? {
        guard let data = line.data(using: .utf8) else { return nil }
        return try? jpdictLineDecoder.decode(JPDictWordRecord.self, from: data)
    }

    private func accentsForJPDictReading(at index: Int, in record: JPDictWordRecord) -> [Int] {
        guard let rm = record.rm,
              rm.indices.contains(index),
              let meta = rm[index],
              let accentValue = meta.a else {
            return []
        }
        switch accentValue {
        case .int(let accent):
            return [accent]
        case .array(let values):
            return values.map(\.i)
        }
    }

    private func parseAccents(_ value: String) -> [Int] {
        value
            .split(separator: ",")
            .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
    }

    private func buildPatterns(from compact: [String: [Int]]) -> [String: [PitchPattern]] {
        var rebuilt: [String: [PitchPattern]] = [:]
        rebuilt.reserveCapacity(compact.count)

        for (key, accents) in compact {
            guard let reading = key.split(separator: ":", maxSplits: 1).last else { continue }
            let uniqueSorted = Array(Set(accents)).sorted()
            guard !uniqueSorted.isEmpty else { continue }
            rebuilt[key] = [
                PitchPattern(
                    pattern: uniqueSorted.map(String.init).joined(separator: ","),
                    moraCount: moraCount(for: String(reading))
                )
            ]
        }

        return rebuilt
    }

    private func normalizeReading(_ reading: String) -> String {
        let converted = reading.applyingTransform(.hiraganaToKatakana, reverse: true) ?? reading
        return converted.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func moraCount(for reading: String) -> Int {
        let smallKana = Set("ゃゅょぁぃぅぇぉャュョァィゥェォゎヮ")
        var count = 0
        for scalar in reading {
            if smallKana.contains(scalar) {
                continue
            }
            count += 1
        }
        return max(count, 1)
    }

    private func ensureCacheDirectoryExists() throws {
        guard let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }
        let dir = appSupportDir.appendingPathComponent("WaniKaniCore", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    private func localCacheURL(fileName: String) -> URL? {
        guard let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return appSupportDir
            .appendingPathComponent("WaniKaniCore", isDirectory: true)
            .appendingPathComponent(fileName, isDirectory: false)
    }

    public func patterns(for characters: String, reading: String) async -> [PitchPattern] {
        await loadIfNeeded()
        let normalizedReading = normalizeReading(reading)
        let exactKey = "\(characters):\(normalizedReading)"
        let wildcardKey = "*:\(normalizedReading)"
        return cache[exactKey] ?? cache[wildcardKey] ?? []
    }
}

private let jpdictLineDecoder = JSONDecoder()

private struct JPDictWordRecord: Decodable {
    let k: [String]?
    let r: [String]
    let rm: [JPDictReadingMeta?]?
}

private struct JPDictReadingMeta: Decodable {
    let a: JPDictAccentField?
}

private struct JPDictAccentObject: Decodable {
    let i: Int
}

private enum JPDictAccentField: Decodable {
    case int(Int)
    case array([JPDictAccentObject])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else {
            self = .array(try container.decode([JPDictAccentObject].self))
        }
    }
}

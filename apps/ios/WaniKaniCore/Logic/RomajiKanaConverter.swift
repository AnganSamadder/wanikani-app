import Foundation

/// Table-driven romaji-to-kana converter with incremental/IME-style conversion.
/// Handles sokuon (double consonant), n disambiguation, and multi-mora clusters.
public struct RomajiKanaConverter: Sendable {
    public enum KanaScript: Sendable {
        case hiragana
        case katakana
    }

    // MARK: - Hiragana Table

    private static let hiraganaTable: [String: String] = [
        // Vowels
        "a": "あ", "i": "い", "u": "う", "e": "え", "o": "お",
        // K row
        "ka": "か", "ki": "き", "ku": "く", "ke": "け", "ko": "こ",
        "kya": "きゃ", "kyu": "きゅ", "kyo": "きょ",
        // S row
        "sa": "さ", "si": "し", "su": "す", "se": "せ", "so": "そ",
        "shi": "し", "sha": "しゃ", "shu": "しゅ", "she": "しぇ", "sho": "しょ",
        "sya": "しゃ", "syu": "しゅ", "syo": "しょ",
        // T row
        "ta": "た", "ti": "ち", "tu": "つ", "te": "て", "to": "と",
        "chi": "ち", "tsu": "つ",
        "cha": "ちゃ", "chu": "ちゅ", "che": "ちぇ", "cho": "ちょ",
        "tya": "ちゃ", "tyu": "ちゅ", "tyo": "ちょ",
        // N row
        "na": "な", "ni": "に", "nu": "ぬ", "ne": "ね", "no": "の",
        "nya": "にゃ", "nyu": "にゅ", "nyo": "にょ",
        // H row
        "ha": "は", "hi": "ひ", "hu": "ふ", "he": "へ", "ho": "ほ",
        "fu": "ふ",
        "hya": "ひゃ", "hyu": "ひゅ", "hyo": "ひょ",
        "fa": "ふぁ", "fi": "ふぃ", "fe": "ふぇ", "fo": "ふぉ",
        // M row
        "ma": "ま", "mi": "み", "mu": "む", "me": "め", "mo": "も",
        "mya": "みゃ", "myu": "みゅ", "myo": "みょ",
        // Y row
        "ya": "や", "yu": "ゆ", "yo": "よ",
        // R row
        "ra": "ら", "ri": "り", "ru": "る", "re": "れ", "ro": "ろ",
        "rya": "りゃ", "ryu": "りゅ", "ryo": "りょ",
        // W row
        "wa": "わ", "wo": "を",
        // N
        "nn": "ん",
        // G row
        "ga": "が", "gi": "ぎ", "gu": "ぐ", "ge": "げ", "go": "ご",
        "gya": "ぎゃ", "gyu": "ぎゅ", "gyo": "ぎょ",
        // Z row
        "za": "ざ", "zi": "じ", "zu": "ず", "ze": "ぜ", "zo": "ぞ",
        "ji": "じ",
        "ja": "じゃ", "ju": "じゅ", "je": "じぇ", "jo": "じょ",
        "jya": "じゃ", "jyu": "じゅ", "jyo": "じょ",
        "zya": "じゃ", "zyu": "じゅ", "zyo": "じょ",
        // D row
        "da": "だ", "di": "ぢ", "du": "づ", "de": "で", "do": "ど",
        "dya": "ぢゃ", "dyu": "ぢゅ", "dyo": "ぢょ",
        // B row
        "ba": "ば", "bi": "び", "bu": "ぶ", "be": "べ", "bo": "ぼ",
        "bya": "びゃ", "byu": "びゅ", "byo": "びょ",
        // P row
        "pa": "ぱ", "pi": "ぴ", "pu": "ぷ", "pe": "ぺ", "po": "ぽ",
        "pya": "ぴゃ", "pyu": "ぴゅ", "pyo": "ぴょ",
        // Special small kana
        "xtu": "っ", "xtsu": "っ",
        "xya": "ゃ", "xyu": "ゅ", "xyo": "ょ",
        "xa": "ぁ", "xi": "ぃ", "xu": "ぅ", "xe": "ぇ", "xo": "ぉ",
        // Long vowel mark
        "-": "ー",
    ]

    private static let katakanaTable: [String: String] = {
        var table: [String: String] = [:]
        for (romaji, hiragana) in hiraganaTable {
            if let katakana = hiragana.applyingTransform(.hiraganaToKatakana, reverse: false) {
                table[romaji] = katakana
            } else {
                table[romaji] = hiragana
            }
        }
        return table
    }()

    private static let vowels: Set<Character> = ["a", "i", "u", "e", "o"]
    private static let consonants: Set<Character> = Set("bcdfghjklmnpqrstvwxyz")

    // MARK: - Public API

    /// Convert a romaji string to kana, leaving unconverted partial clusters as romaji.
    /// - Parameters:
    ///   - input: Romaji input string
    ///   - targetScript: .hiragana or .katakana
    /// - Returns: String with converted kana and any trailing partial romaji cluster
    public static func convert(_ input: String, targetScript: KanaScript) -> String {
        let table = targetScript == .hiragana ? hiraganaTable : katakanaTable
        var result = ""
        let chars = Array(input.lowercased())
        var i = 0

        while i < chars.count {
            let c = chars[i]

            // Handle sokuon: double consonant (e.g. "tt" -> "っt")
            if consonants.contains(c) && c != "n" && i + 1 < chars.count && chars[i + 1] == c {
                let sokuon = targetScript == .hiragana ? "っ" : "ッ"
                result += sokuon
                i += 1
                continue
            }

            // Handle "n" disambiguation
            if c == "n" {
                // "nn" -> ん/ン
                if i + 1 < chars.count && chars[i + 1] == "n" {
                    let n = targetScript == .hiragana ? "ん" : "ン"
                    result += n
                    i += 2
                    continue
                }
                // "n" followed by consonant (not 'y') -> ん/ン
                if i + 1 < chars.count {
                    let next = chars[i + 1]
                    if consonants.contains(next) && next != "y" {
                        let n = targetScript == .hiragana ? "ん" : "ン"
                        result += n
                        i += 1
                        continue
                    }
                }
                // "n" at end of string -> ん/ン
                if i + 1 >= chars.count {
                    let n = targetScript == .hiragana ? "ん" : "ン"
                    result += n
                    i += 1
                    continue
                }
                // Otherwise let it fall through to normal matching (e.g. "na", "ni", etc.)
            }

            // Try longest match first (4, 3, 2, 1 chars)
            var matched = false
            for length in [4, 3, 2, 1] {
                let end = i + length
                guard end <= chars.count else { continue }
                let cluster = String(chars[i..<end])
                if let kana = table[cluster] {
                    result += kana
                    i += length
                    matched = true
                    break
                }
            }

            if !matched {
                // No match — pass character through as-is (partial cluster or unknown)
                result += String(c)
                i += 1
            }
        }

        return result
    }

    /// Returns true if the converted string has no trailing partial romaji cluster.
    public static func isCommitted(_ cluster: String) -> Bool {
        guard let last = cluster.last else { return true }
        let lower = last.lowercased().first ?? last
        return !consonants.contains(lower) || lower == "n"
    }
}

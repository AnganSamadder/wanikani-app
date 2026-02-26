import Foundation

/// Engine for checking user answers against accepted meanings and readings
public struct AnswerChecker: Sendable {
    
    /// Normalizes user input for comparison
    private static func normalize(_ input: String) -> String {
        input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ".", with: "")
    }
    
    /// Checks if the user's answer matches any of the accepted answers
    /// - Parameters:
    ///   - userAnswer: The user's input
    ///   - acceptedAnswers: Array of accepted answer strings
    /// - Returns: True if the answer matches (case-insensitive, trimmed)
    public static func checkAnswer(_ userAnswer: String, against acceptedAnswers: [String]) -> Bool {
        let normalizedUser = normalize(userAnswer)
        guard !normalizedUser.isEmpty else { return false }
        
        return acceptedAnswers.contains { accepted in
            normalize(accepted) == normalizedUser
        }
    }
    
    /// Checks if a meaning answer is correct
    /// - Parameters:
    ///   - userAnswer: The user's input
    ///   - subject: The subject snapshot containing accepted meanings
    /// - Returns: True if the answer matches an accepted meaning
    public static func checkMeaning(_ userAnswer: String, for subject: SubjectSnapshot) -> Bool {
        checkAnswer(userAnswer, against: subject.acceptedMeanings)
    }
    
    /// Checks if a reading answer is correct
    /// - Parameters:
    ///   - userAnswer: The user's input
    ///   - subject: The subject snapshot containing accepted readings
    /// - Returns: True if the answer matches an accepted reading
    public static func checkReading(_ userAnswer: String, for subject: SubjectSnapshot) -> Bool {
        checkReadingWithRomaji(userAnswer, for: subject)
    }

    /// Checks if a reading answer is correct, also trying romaji-to-kana conversion.
    /// Attempts: raw input, hiragana conversion, katakana conversion.
    public static func checkReadingWithRomaji(_ userAnswer: String, for subject: SubjectSnapshot) -> Bool {
        // 1. Raw input check
        if checkAnswer(userAnswer, against: subject.acceptedReadings) {
            return true
        }
        // 2. Hiragana conversion
        let hiragana = RomajiKanaConverter.convert(userAnswer, targetScript: .hiragana)
        if checkAnswer(hiragana, against: subject.acceptedReadings) {
            return true
        }
        // 3. Katakana conversion (for on'yomi)
        let katakana = RomajiKanaConverter.convert(userAnswer, targetScript: .katakana)
        if checkAnswer(katakana, against: subject.acceptedReadings) {
            return true
        }
        return false
    }
}

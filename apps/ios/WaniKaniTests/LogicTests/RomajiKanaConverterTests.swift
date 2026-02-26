import XCTest
@testable import WaniKaniCore

final class RomajiKanaConverterTests: XCTestCase {
    func test_convert_hiragana_murabito() {
        XCTAssertEqual(RomajiKanaConverter.convert("murabito", targetScript: .hiragana), "むらびと")
    }

    func test_convert_sokuon_doubleConsonant_keepsTrailingCluster() {
        XCTAssertEqual(RomajiKanaConverter.convert("tt", targetScript: .hiragana), "っt")
    }

    func test_convert_nn_toN() {
        XCTAssertEqual(RomajiKanaConverter.convert("nn", targetScript: .hiragana), "ん")
    }

    func test_convert_onyomi_toKatakana() {
        XCTAssertEqual(RomajiKanaConverter.convert("gen", targetScript: .katakana), "ゲン")
    }

    func test_answerChecker_checkReading_acceptsRomajiForHiraganaReading() {
        let subject = SubjectSnapshot(
            id: 1,
            object: "vocabulary",
            characters: "村人",
            slug: "murabito",
            level: 1,
            meanings: [MeaningSnapshot(meaning: "Villager", primary: true, acceptedAnswer: true)],
            readings: [ReadingSnapshot(reading: "むらびと", primary: true, acceptedAnswer: true, type: nil)]
        )

        XCTAssertTrue(AnswerChecker.checkReading("murabito", for: subject))
    }

    func test_answerChecker_checkReading_acceptsRomajiForKatakanaReading() {
        let subject = SubjectSnapshot(
            id: 2,
            object: "kanji",
            characters: "言",
            slug: "say",
            level: 1,
            meanings: [MeaningSnapshot(meaning: "Say", primary: true, acceptedAnswer: true)],
            readings: [ReadingSnapshot(reading: "ゲン", primary: true, acceptedAnswer: true, type: "onyomi")]
        )

        XCTAssertTrue(AnswerChecker.checkReading("gen", for: subject))
    }

    func test_answerChecker_checkReading_acceptsKatakanaInputForHiraganaReading() {
        let subject = SubjectSnapshot(
            id: 4,
            object: "kanji",
            characters: "新",
            slug: "new",
            level: 1,
            meanings: [MeaningSnapshot(meaning: "New", primary: true, acceptedAnswer: true)],
            readings: [ReadingSnapshot(reading: "しん", primary: true, acceptedAnswer: true, type: "onyomi")]
        )

        XCTAssertTrue(AnswerChecker.checkReading("シン", for: subject))
    }

    func test_answerChecker_checkReading_acceptsHiraganaInputForKatakanaReading() {
        let subject = SubjectSnapshot(
            id: 5,
            object: "kanji",
            characters: "言",
            slug: "say",
            level: 1,
            meanings: [MeaningSnapshot(meaning: "Say", primary: true, acceptedAnswer: true)],
            readings: [ReadingSnapshot(reading: "ゲン", primary: true, acceptedAnswer: true, type: "onyomi")]
        )

        XCTAssertTrue(AnswerChecker.checkReading("げん", for: subject))
    }

    func test_answerChecker_checkMeaning_acceptsUserSynonyms() {
        let subject = SubjectSnapshot(
            id: 3,
            object: "kanji",
            characters: "言",
            slug: "say",
            level: 1,
            meanings: [MeaningSnapshot(meaning: "Say", primary: true, acceptedAnswer: true)],
            readings: []
        )

        XCTAssertTrue(AnswerChecker.checkMeaning("utter", for: subject, userSynonyms: ["utter"]))
    }
}

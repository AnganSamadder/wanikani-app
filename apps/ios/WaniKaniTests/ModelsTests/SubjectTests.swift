import XCTest
@testable import WaniKaniCore

final class SubjectTests: XCTestCase {
    
    private var decoder: JSONDecoder!
    
    override func setUp() {
        super.setUp()
        decoder = .wanikaniDecoder()
    }
    
    func test_radical_decodesFromJSON() throws {
        let json = """
        {
            "id": 1,
            "object": "radical",
            "url": "https://api.wanikani.com/v2/subjects/1",
            "data_updated_at": "2023-05-12T10:00:00.000Z",
            "data": {
                "created_at": "2012-02-27T19:08:16.000Z",
                "level": 1,
                "slug": "ground",
                "hidden_at": null,
                "document_url": "https://www.wanikani.com/radicals/ground",
                "characters": "一",
                "character_images": [],
                "meanings": [
                    {
                        "meaning": "Ground",
                        "primary": true,
                        "accepted_answer": true
                    }
                ],
                "auxiliary_meanings": [],
                "amalgamation_subject_ids": [440, 449],
                "meaning_mnemonic": "This is the ground.",
                "lesson_position": 0,
                "spaced_repetition_system_id": 1
            }
        }
        """.data(using: .utf8)!
        
        let radical = try decoder.decode(Radical.self, from: json)
        
        XCTAssertEqual(radical.id, 1)
        XCTAssertEqual(radical.object, "radical")
        XCTAssertEqual(radical.data.level, 1)
        XCTAssertEqual(radical.data.slug, "ground")
        XCTAssertEqual(radical.data.characters, "一")
        XCTAssertEqual(radical.data.meanings.first?.meaning, "Ground")
        XCTAssertTrue(radical.data.meanings.first?.primary ?? false)
    }
    
    func test_kanji_decodesFromJSON() throws {
        let json = """
        {
            "id": 440,
            "object": "kanji",
            "url": "https://api.wanikani.com/v2/subjects/440",
            "data_updated_at": "2023-06-01T12:00:00.000Z",
            "data": {
                "created_at": "2012-02-27T19:08:16.000Z",
                "level": 1,
                "slug": "one",
                "hidden_at": null,
                "document_url": "https://www.wanikani.com/kanji/一",
                "characters": "一",
                "meanings": [
                    {
                        "meaning": "One",
                        "primary": true,
                        "accepted_answer": true
                    }
                ],
                "auxiliary_meanings": [],
                "readings": [
                    {
                        "reading": "いち",
                        "primary": true,
                        "accepted_answer": true,
                        "type": "onyomi"
                    }
                ],
                "component_subject_ids": [1],
                "amalgamation_subject_ids": [2467, 2468],
                "visually_similar_subject_ids": [],
                "meaning_mnemonic": "One meaning mnemonic",
                "meaning_hint": null,
                "reading_mnemonic": "One reading mnemonic",
                "reading_hint": null,
                "lesson_position": 0,
                "spaced_repetition_system_id": 1
            }
        }
        """.data(using: .utf8)!
        
        let kanji = try decoder.decode(Kanji.self, from: json)
        
        XCTAssertEqual(kanji.id, 440)
        XCTAssertEqual(kanji.object, "kanji")
        XCTAssertEqual(kanji.data.characters, "一")
        XCTAssertEqual(kanji.data.readings.first?.reading, "いち")
        XCTAssertEqual(kanji.data.readings.first?.type, "onyomi")
    }
    
    func test_vocabulary_decodesFromJSON() throws {
        let json = """
        {
            "id": 2467,
            "object": "vocabulary",
            "url": "https://api.wanikani.com/v2/subjects/2467",
            "data_updated_at": "2023-07-01T12:00:00.000Z",
            "data": {
                "created_at": "2012-02-27T19:08:16.000Z",
                "level": 1,
                "slug": "one",
                "hidden_at": null,
                "document_url": "https://www.wanikani.com/vocabulary/一",
                "characters": "一",
                "meanings": [
                    {
                        "meaning": "One",
                        "primary": true,
                        "accepted_answer": true
                    }
                ],
                "auxiliary_meanings": [],
                "readings": [
                    {
                        "reading": "いち",
                        "primary": true,
                        "accepted_answer": true,
                        "type": null
                    }
                ],
                "parts_of_speech": ["numeral"],
                "component_subject_ids": [440],
                "meaning_mnemonic": "Vocabulary meaning mnemonic",
                "reading_mnemonic": "Vocabulary reading mnemonic",
                "context_sentences": [
                    {
                        "en": "It's one.",
                        "ja": "一です。"
                    }
                ],
                "pronunciation_audios": [],
                "lesson_position": 0,
                "spaced_repetition_system_id": 1
            }
        }
        """.data(using: .utf8)!
        
        let vocabulary = try decoder.decode(Vocabulary.self, from: json)
        
        XCTAssertEqual(vocabulary.id, 2467)
        XCTAssertEqual(vocabulary.object, "vocabulary")
        XCTAssertEqual(vocabulary.data.characters, "一")
        XCTAssertEqual(vocabulary.data.partsOfSpeech.first, "numeral")
        XCTAssertEqual(vocabulary.data.contextSentences.first?.ja, "一です。")
    }
    
    func test_subjectType_decodesAllCases() throws {
        let cases: [(String, SubjectType)] = [
            ("radical", .radical),
            ("kanji", .kanji),
            ("vocabulary", .vocabulary),
            ("kana_vocabulary", .kanaVocabulary)
        ]
        
        for (jsonValue, expectedType) in cases {
            let json = "\"\(jsonValue)\"".data(using: .utf8)!
            let type = try decoder.decode(SubjectType.self, from: json)
            XCTAssertEqual(type, expectedType)
        }
    }
}

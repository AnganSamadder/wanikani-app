import XCTest
import SwiftData
@testable import WaniKaniCore

@MainActor
final class PersistenceManagerTests: XCTestCase {
    var sut: PersistenceManager!
    
    override func setUp() {
        super.setUp()
        sut = PersistenceManager(inMemory: true)
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func test_init_createsContainer() {
        XCTAssertNotNil(sut.container)
        XCTAssertNotNil(sut.context)
    }
    
    func test_saveUser_persistsUser() throws {
        // Given
        let user = User.mock()
        
        // When
        sut.saveUser(user)
        
        // Then
        let fetchedUser = sut.fetchUser()
        XCTAssertNotNil(fetchedUser)
        XCTAssertEqual(fetchedUser?.id, user.id)
        XCTAssertEqual(fetchedUser?.username, user.username)
    }
    
    func test_fetchUser_returnsNilWhenEmpty() {
        let fetchedUser = sut.fetchUser()
        XCTAssertNil(fetchedUser)
    }

    func test_pendingReviewCRUD_andHalfCompletionCount() throws {
        let pending = PendingReviewSnapshot(
            assignmentID: 100,
            subjectID: 200,
            subjectType: "kanji",
            hasReadings: true,
            meaningCompleted: true,
            readingCompleted: false,
            incorrectMeaningAnswers: 1,
            incorrectReadingAnswers: 0,
            updatedAt: Date()
        )

        try sut.upsertPendingReview(pending)
        XCTAssertEqual(sut.fetchPendingReview(assignmentID: 100)?.isHalfComplete, true)
        XCTAssertEqual(sut.countHalfCompletions(), 1)

        try sut.deletePendingReview(assignmentID: 100)
        XCTAssertNil(sut.fetchPendingReview(assignmentID: 100))
        XCTAssertEqual(sut.countHalfCompletions(), 0)
    }

    func test_saveStudyMaterialSnapshot_andFetch() throws {
        let snapshot = StudyMaterialSnapshot(
            subjectID: 300,
            meaningNote: "Meaning note",
            readingNote: "Reading note",
            meaningSynonyms: ["Alias"],
            updatedAt: Date()
        )

        try sut.saveStudyMaterialSnapshot(snapshot)

        let loaded = sut.fetchStudyMaterial(subjectID: 300)
        XCTAssertEqual(loaded?.meaningNote, "Meaning note")
        XCTAssertEqual(loaded?.readingNote, "Reading note")
        XCTAssertEqual(loaded?.meaningSynonyms, ["Alias"])
    }

    func test_saveSubjects_persistsRelationshipAndDetailFields() {
        let createdAt = Date()
        let subject = SubjectData(
            id: 999,
            object: "vocabulary",
            url: "https://api.wanikani.com/v2/subjects/999",
            dataUpdatedAt: createdAt,
            data: .vocabulary(
                VocabularyData(
                    createdAt: createdAt,
                    level: 12,
                    slug: "ことば",
                    hiddenAt: nil,
                    documentURL: "https://www.wanikani.com/vocabulary/%E8%A8%80%E8%91%89",
                    characters: "言葉",
                    meanings: [Meaning(meaning: "Word", primary: true, acceptedAnswer: true)],
                    auxiliaryMeanings: [],
                    readings: [Reading(reading: "ことば", primary: true, acceptedAnswer: true)],
                    partsOfSpeech: ["noun"],
                    componentSubjectIDs: [111, 222],
                    meaningMnemonic: "Meaning mnemonic",
                    readingMnemonic: "Reading mnemonic",
                    contextSentences: [
                        ContextSentence(en: "Words matter.", ja: "言葉は大事です。")
                    ],
                    pronunciationAudios: [
                        PronunciationAudio(url: "https://audio.example/test.mp3", contentType: "audio/mpeg")
                    ],
                    lessonPosition: 1,
                    spacedRepetitionSystemID: 1
                )
            )
        )

        sut.saveSubjects([subject])
        let snapshot = sut.fetchSubjectSnapshot(id: 999)

        XCTAssertEqual(snapshot?.componentSubjectIDs, [111, 222])
        XCTAssertEqual(snapshot?.partsOfSpeech, ["noun"])
        XCTAssertEqual(snapshot?.contextSentences.count, 1)
        XCTAssertEqual(snapshot?.pronunciationAudios.count, 1)
    }
}

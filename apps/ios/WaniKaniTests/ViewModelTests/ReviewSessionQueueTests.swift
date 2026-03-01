import XCTest
import WaniKaniCore
@testable import WaniKani

// Tests covering TTL re-queue, companion queue persistence, and fast-forward mode.
// These complement ReviewSessionViewModelTests which covers the broader session lifecycle.
@MainActor
final class ReviewSessionQueueTests: XCTestCase {

    private var reviewRepository: MockReviewSessionRepository!
    private var subjectRepository: MockSubjectDetailRepository!
    private var subjectRelationsRepository: MockSubjectRelationsRepository!
    private var studyMaterialRepository: MockStudyMaterialRepository!

    override func setUp() {
        super.setUp()
        reviewRepository = MockReviewSessionRepository()
        subjectRepository = MockSubjectDetailRepository()
        subjectRelationsRepository = MockSubjectRelationsRepository()
        studyMaterialRepository = MockStudyMaterialRepository()
    }

    override func tearDown() {
        reviewRepository = nil
        subjectRepository = nil
        subjectRelationsRepository = nil
        studyMaterialRepository = nil
        super.tearDown()
    }

    // MARK: - Factory helpers

    private func makeSUT(reviewTTL: Int = 0) -> ReviewSessionViewModel {
        ReviewSessionViewModel(
            reviewSessionRepository: reviewRepository,
            subjectDetailRepository: subjectRepository,
            subjectRelationsRepository: subjectRelationsRepository,
            studyMaterialRepository: studyMaterialRepository,
            reviewTTL: reviewTTL
        )
    }

    private func makeAssignment(
        id: Int,
        subjectID: Int,
        type: SubjectType = .kanji
    ) -> AssignmentSnapshot {
        AssignmentSnapshot(
            id: id, subjectID: subjectID, subjectType: type, srsStage: 1,
            availableAt: Date(), unlockedAt: Date(), startedAt: Date(),
            passedAt: nil, burnedAt: nil, hidden: false
        )
    }

    private func makeKanji(
        id: Int, characters: String, meaning: String, reading: String
    ) -> SubjectSnapshot {
        SubjectSnapshot(
            id: id, object: "kanji", characters: characters,
            slug: meaning.lowercased(), level: 1,
            meanings: [MeaningSnapshot(meaning: meaning, primary: true, acceptedAnswer: true)],
            readings: [ReadingSnapshot(reading: reading, primary: true, acceptedAnswer: true, type: "onyomi")]
        )
    }

    private func makeRadical(
        id: Int, characters: String, meaning: String
    ) -> SubjectSnapshot {
        SubjectSnapshot(
            id: id, object: "radical", characters: characters,
            slug: meaning.lowercased(), level: 1,
            meanings: [MeaningSnapshot(meaning: meaning, primary: true, acceptedAnswer: true)],
            readings: []
        )
    }

    private func makeReview(id: Int, assignmentID: Int, subjectID: Int) -> Review {
        Review(
            id: id, object: "review", url: "", dataUpdatedAt: nil,
            data: ReviewData(
                createdAt: Date(), assignmentID: assignmentID, subjectID: subjectID,
                spacedRepetitionSystemID: 1, startingSRSStage: 1, endingSRSStage: 2,
                incorrectMeaningAnswers: 0, incorrectReadingAnswers: 0
            )
        )
    }

    private func registerSubject(_ subject: SubjectSnapshot) {
        subjectRepository.subjectsByID[subject.id] = subject
        subjectRelationsRepository.subjectsByID[subject.id] = subject
    }

    // MARK: - TTL Re-queue

    func test_ttl_wrongAnswer_requeuedItemIncreasesRemainingCount() async {
        // Wrong answer should re-queue the item, increasing the pool.
        // A kanji starts with 2 questions; after a wrong answer the count
        // temporarily becomes 3: current (held) + re-queued + unseen other side.
        let sut = makeSUT(reviewTTL: 0)
        let assignment = makeAssignment(id: 50, subjectID: 500)
        let subject = makeKanji(id: 500, characters: "水", meaning: "Water", reading: "すい")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)

        await sut.load()
        XCTAssertEqual(sut.remainingCount, 2)

        sut.userAnswer = "not-water"
        await sut.submitCurrentAnswer()

        // Current item still held in feedback + re-queued wrong item + unseen other side = 3
        XCTAssertEqual(sut.remainingCount, 3)
        XCTAssertEqual(sut.lastAnswerCorrect, false)
    }

    func test_ttl_wrongAnswer_tracksIncorrectCount_inPendingReview() async {
        // A wrong answer should record the incorrect count in the pending review.
        let sut = makeSUT()
        let assignment = makeAssignment(id: 51, subjectID: 501)
        let subject = makeKanji(id: 501, characters: "火", meaning: "Fire", reading: "か")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)

        await sut.load()
        guard let prompt = sut.prompt else { XCTFail("Expected prompt"); return }

        sut.userAnswer = "ice"
        await sut.submitCurrentAnswer()

        guard let pending = reviewRepository.pendingReviews[assignment.id] else {
            XCTFail("Pending review should be saved after wrong answer")
            return
        }
        XCTAssertEqual(
            pending.incorrectMeaningAnswers + pending.incorrectReadingAnswers, 1
        )
        if prompt.questionType == .meaning {
            XCTAssertEqual(pending.incorrectMeaningAnswers, 1)
            XCTAssertEqual(pending.incorrectReadingAnswers, 0)
        } else {
            XCTAssertEqual(pending.incorrectMeaningAnswers, 0)
            XCTAssertEqual(pending.incorrectReadingAnswers, 1)
        }
    }

    func test_ttl_withTTL1_wrongAnswerReturnsAfterOneMoreStep() async {
        // TTL=1: the wrong-answered item must come back as the third prompt.
        // Sequence: answer Q1 wrong → answer Q2 correctly → Q1 re-served.
        let sut = makeSUT(reviewTTL: 1)
        let assignment = makeAssignment(id: 52, subjectID: 502)
        let subject = makeKanji(id: 502, characters: "山", meaning: "Mountain", reading: "さん")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)
        reviewRepository.mockReview = makeReview(id: 100, assignmentID: 52, subjectID: 502)

        await sut.load()
        guard let firstPrompt = sut.prompt else { XCTFail(); return }
        let firstType = firstPrompt.questionType

        sut.userAnswer = "wrong"
        await sut.submitCurrentAnswer()
        await sut.next()

        // Second question is the other side
        guard let secondPrompt = sut.prompt else { XCTFail("Expected second question"); return }
        XCTAssertNotEqual(secondPrompt.questionType, firstType)
        sut.userAnswer = secondPrompt.questionType == .meaning ? "Mountain" : "さん"
        await sut.submitCurrentAnswer()
        await sut.next()

        // With TTL=1, readyAtStep = stepCount(1) + 1 = 2; after 2 steps stepCount=2,
        // so the re-queued item is now ready and should be the third prompt.
        guard let thirdPrompt = sut.prompt else { XCTFail("Expected third question (re-served wrong item)"); return }
        XCTAssertEqual(thirdPrompt.questionType, firstType,
                       "Re-queued item should return after exactly TTL more steps")
        XCTAssertEqual(sut.state, .ready)
    }

    func test_ttl_withTTL2_wrongAnswerNotServedBeforeDelay() async {
        // TTL=2: wrong answer should NOT be served again within a 2-question session.
        // After answering both sides (1 wrong, 1 correct) → 2 steps, but re-queued
        // item needs 3 steps → session ends without re-serving the wrong item.
        let sut = makeSUT(reviewTTL: 2)
        let assignment = makeAssignment(id: 53, subjectID: 503)
        let subject = makeKanji(id: 503, characters: "木", meaning: "Tree", reading: "き")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)

        await sut.load()
        XCTAssertEqual(sut.state, .ready)

        sut.userAnswer = "definitely-wrong"
        await sut.submitCurrentAnswer()
        await sut.next()

        guard let secondPrompt = sut.prompt else { XCTFail("Expected second question"); return }
        sut.userAnswer = secondPrompt.questionType == .meaning ? "Tree" : "き"
        await sut.submitCurrentAnswer()
        await sut.next()

        // readyAtStep = 3, stepCount = 2 → not ready → both queues drain → complete
        XCTAssertEqual(sut.state, .complete)
        // Meaning side was never correctly answered; review was never submitted
        XCTAssertTrue(reviewRepository.submitReviewCalls.isEmpty,
                      "Review should not be submitted if item was not fully completed")
    }

    func test_ttl_multipleWrongAnswers_accumulateIncorrectCounts() async {
        // Answering the same question wrong multiple times should accumulate the
        // incorrect count. Use a radical (meaning-only) so there is only one question
        // type — no 50/50 randomness between queue choices.
        let sut = makeSUT(reviewTTL: 0)
        let assignment = makeAssignment(id: 54, subjectID: 504, type: .radical)
        let subject = makeRadical(id: 504, characters: "土", meaning: "Earth")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)
        reviewRepository.mockReview = makeReview(id: 101, assignmentID: 54, subjectID: 504)

        await sut.load()
        XCTAssertEqual(sut.remainingCount, 1)  // radical: meaning only

        // Wrong, wrong, then correct
        sut.userAnswer = "wrong"
        await sut.submitCurrentAnswer()
        await sut.next()

        sut.userAnswer = "also-wrong"
        await sut.submitCurrentAnswer()
        await sut.next()

        sut.userAnswer = "Earth"
        await sut.submitCurrentAnswer()
        await sut.next()

        XCTAssertEqual(sut.state, .complete)
        guard let call = reviewRepository.submitReviewCalls.first else {
            XCTFail("Review should be submitted after correct answer on radical")
            return
        }
        XCTAssertEqual(call.incorrectMeaningAnswers, 2,
                       "Both wrong attempts should be recorded in the final submit")
        XCTAssertEqual(call.incorrectReadingAnswers, 0)
    }

    // MARK: - Companion Queue — Persistence

    func test_companion_correctAnswer_persistsCompanionForOtherSide() async {
        // After correctly answering one side of a kanji, the other side should be
        // stored in the companion queue (to survive app restart).
        let sut = makeSUT()
        let assignment = makeAssignment(id: 55, subjectID: 505)
        let subject = makeKanji(id: 505, characters: "人", meaning: "Person", reading: "ひと")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)

        await sut.load()
        guard let prompt = sut.prompt else { XCTFail("Expected prompt"); return }

        sut.userAnswer = prompt.questionType == .meaning ? "Person" : "ひと"
        await sut.submitCurrentAnswer()

        let expectedCompanionType = prompt.questionType == .meaning ? "Reading" : "Meaning"
        XCTAssertNotNil(
            reviewRepository.activeQueueItems["\(assignment.id)-\(expectedCompanionType)"],
            "Companion \(expectedCompanionType) should be persisted after correct answer"
        )
    }

    func test_companion_wrongAnswer_doesNotPersistCompanion() async {
        // A wrong answer should NOT persist a companion — companions are only
        // added on correct answers.
        let sut = makeSUT()
        let assignment = makeAssignment(id: 56, subjectID: 506)
        let subject = makeKanji(id: 506, characters: "月", meaning: "Moon", reading: "つき")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)

        await sut.load()
        sut.userAnswer = "wrong"
        await sut.submitCurrentAnswer()

        XCTAssertTrue(reviewRepository.activeQueueItems.isEmpty,
                      "No companion should be persisted after a wrong answer")
    }

    func test_companion_notPersistedForRadical_noReadings() async {
        // Radicals only have a meaning question. Answering it correctly should
        // not create a companion entry (there is no reading side).
        let sut = makeSUT()
        let assignment = makeAssignment(id: 57, subjectID: 507, type: .radical)
        let subject = makeRadical(id: 507, characters: "口", meaning: "Mouth")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)

        await sut.load()
        sut.userAnswer = "Mouth"
        await sut.submitCurrentAnswer()

        XCTAssertTrue(reviewRepository.activeQueueItems.isEmpty,
                      "No companion should be added for a radical (no reading side)")
    }

    func test_companion_notDuplicated_whenAlreadyInQueue() async {
        // If the companion side is already in the active queue (e.g. from a previous
        // wrong-answer re-queue), no duplicate companion entry should be created.
        let sut = makeSUT(reviewTTL: 0)
        let assignment = makeAssignment(id: 58, subjectID: 508)
        let subject = makeKanji(id: 508, characters: "日", meaning: "Day", reading: "ひ")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)

        await sut.load()
        guard let firstPrompt = sut.prompt else { XCTFail(); return }
        let firstType = firstPrompt.questionType
        let otherType = firstType == .meaning ? "Reading" : "Meaning"

        // Answer first side wrong → it gets re-queued in activeQueue
        sut.userAnswer = "wrong"
        await sut.submitCurrentAnswer()
        await sut.next()

        // Answer the other side correctly.
        // The wrong-answered side is already in activeQueue, so companion should not be added.
        guard let secondPrompt = sut.prompt else { XCTFail(); return }
        sut.userAnswer = secondPrompt.questionType == .meaning ? "Day" : "ひ"
        await sut.submitCurrentAnswer()

        // The correct-answered side should be removed from companion persistence.
        // The wrong-answered side should NOT have been added as a companion (already in active).
        let companionKey = "\(assignment.id)-\(firstType.rawValue)"
        XCTAssertNil(reviewRepository.activeQueueItems[companionKey],
                     "Wrong-answered item already in activeQueue; must not be duplicated as companion")
        _ = otherType // suppress unused warning
    }

    func test_companion_deletedFromPersistence_whenCompanionSideAnsweredCorrectly() async {
        // Once the companion side is answered correctly, its persistence entry should
        // be removed (it's been served and is no longer needed).
        let sut = makeSUT()
        let assignment = makeAssignment(id: 59, subjectID: 509)
        let subject = makeKanji(id: 509, characters: "年", meaning: "Year", reading: "ねん")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)
        reviewRepository.mockReview = makeReview(id: 102, assignmentID: 59, subjectID: 509)

        await sut.load()
        guard let firstPrompt = sut.prompt else { XCTFail(); return }
        let companionType = firstPrompt.questionType == .meaning ? "Reading" : "Meaning"
        let companionKey = "\(assignment.id)-\(companionType)"

        // Answer first side correctly → companion persisted
        sut.userAnswer = firstPrompt.questionType == .meaning ? "Year" : "ねん"
        await sut.submitCurrentAnswer()
        XCTAssertNotNil(reviewRepository.activeQueueItems[companionKey])

        await sut.next()

        // Answer companion side correctly → its entry should be deleted
        guard let secondPrompt = sut.prompt else { XCTFail("Expected companion question"); return }
        sut.userAnswer = secondPrompt.questionType == .meaning ? "Year" : "ねん"
        await sut.submitCurrentAnswer()

        XCTAssertNil(reviewRepository.activeQueueItems[companionKey],
                     "Companion persistence entry should be deleted once that side is answered correctly")
    }

    func test_companion_correctAnswerOnFirstSide_deletesItsOwnCompanionEntry() async {
        // When a side is answered correctly, its own companion entry (if any was
        // pre-loaded from a previous session) should also be deleted from persistence.
        let sut = makeSUT()
        let assignment = makeAssignment(id: 60, subjectID: 510)
        let subject = makeKanji(id: 510, characters: "川", meaning: "River", reading: "かわ")
        // Pre-load a "Meaning" companion entry as if a previous session left it
        reviewRepository.activeQueueItems["\(assignment.id)-Meaning"] = ActiveQueueItemSnapshot(
            assignmentID: assignment.id, subjectID: subject.id,
            subjectType: "kanji", questionType: "Meaning"
        )
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)

        await sut.load()
        // Serve the meaning question (it will be in activeQueue since it was a companion)
        // and answer it correctly
        guard let prompt = sut.prompt else { XCTFail(); return }
        if prompt.questionType == .meaning {
            sut.userAnswer = "River"
            await sut.submitCurrentAnswer()
            // Its own companion entry should be deleted
            XCTAssertNil(reviewRepository.activeQueueItems["\(assignment.id)-Meaning"],
                         "Own companion entry should be deleted when side is answered correctly")
        } else {
            // Reading was served first (companion was in active); answer it
            sut.userAnswer = "かわ"
            await sut.submitCurrentAnswer()
            XCTAssertNil(reviewRepository.activeQueueItems["\(assignment.id)-Reading"],
                         "Own companion entry deleted on correct answer")
        }
    }

    // MARK: - Companion Queue — Queue Interaction

    func test_companion_movedFromUnseenToActive_onCorrectAnswer() async {
        // When a companion is added to activeQueue, it must also be removed from
        // unseenQueue to prevent the same item from appearing in both queues.
        // remainingCount should stay constant (not increase by 1).
        let sut = makeSUT()
        let assignment = makeAssignment(id: 61, subjectID: 511)
        let subject = makeKanji(id: 511, characters: "風", meaning: "Wind", reading: "かぜ")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)

        await sut.load()
        let initialRemaining = sut.remainingCount  // 2 (meaning + reading)

        guard let prompt = sut.prompt else { XCTFail(); return }
        sut.userAnswer = prompt.questionType == .meaning ? "Wind" : "かぜ"
        await sut.submitCurrentAnswer()

        // Companion moved unseen→active: total count unchanged
        // (1 in active + 0 in unseen + 1 current = 2)
        XCTAssertEqual(sut.remainingCount, initialRemaining,
                       "Moving companion unseen→active must not change total remaining count")
    }

    // MARK: - Companion Queue — Undo

    func test_undo_afterCorrectAnswer_removesCompanionFromPersistence() async {
        // Undo after a correct answer should delete the companion that was just added.
        let sut = makeSUT()
        let assignment = makeAssignment(id: 62, subjectID: 512)
        let subject = makeKanji(id: 512, characters: "空", meaning: "Sky", reading: "そら")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)

        await sut.load()
        guard let prompt = sut.prompt else { XCTFail(); return }
        let companionType = prompt.questionType == .meaning ? "Reading" : "Meaning"
        let companionKey = "\(assignment.id)-\(companionType)"

        sut.userAnswer = prompt.questionType == .meaning ? "Sky" : "そら"
        await sut.submitCurrentAnswer()
        XCTAssertNotNil(reviewRepository.activeQueueItems[companionKey])

        await sut.undo()

        XCTAssertNil(reviewRepository.activeQueueItems[companionKey],
                     "Companion should be removed from persistence when answer is undone")
    }

    func test_undo_afterCorrectAnswer_restoresPromptAndRemainingCount() async {
        // After undoing a correct answer, the prompt and remaining count should
        // both be identical to what they were before the answer.
        let sut = makeSUT()
        let assignment = makeAssignment(id: 63, subjectID: 513)
        let subject = makeKanji(id: 513, characters: "雨", meaning: "Rain", reading: "あめ")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)

        await sut.load()
        let beforePrompt = sut.prompt
        let beforeRemaining = sut.remainingCount

        guard let prompt = sut.prompt else { XCTFail(); return }
        sut.userAnswer = prompt.questionType == .meaning ? "Rain" : "あめ"
        await sut.submitCurrentAnswer()

        await sut.undo()

        XCTAssertEqual(sut.prompt, beforePrompt)
        XCTAssertEqual(sut.remainingCount, beforeRemaining)
        XCTAssertFalse(sut.canUndo)
        XCTAssertEqual(sut.phase, .answering)
    }

    func test_undo_afterCorrectAnswer_companionRestoredToUnseenForReplay() async {
        // If undo restores a companion back to unseenQueue, answering correctly again
        // should re-add the companion (demonstrating the state was cleanly reversed).
        let sut = makeSUT()
        let assignment = makeAssignment(id: 64, subjectID: 514)
        let subject = makeKanji(id: 514, characters: "花", meaning: "Flower", reading: "はな")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)

        await sut.load()
        guard let prompt = sut.prompt else { XCTFail(); return }
        let companionType = prompt.questionType == .meaning ? "Reading" : "Meaning"
        let companionKey = "\(assignment.id)-\(companionType)"

        // Answer correctly → companion added
        sut.userAnswer = prompt.questionType == .meaning ? "Flower" : "はな"
        await sut.submitCurrentAnswer()
        XCTAssertNotNil(reviewRepository.activeQueueItems[companionKey])

        // Undo → companion removed
        await sut.undo()
        XCTAssertNil(reviewRepository.activeQueueItems[companionKey])

        // Answer the same question correctly again → companion re-added
        sut.userAnswer = prompt.questionType == .meaning ? "Flower" : "はな"
        await sut.submitCurrentAnswer()
        XCTAssertNotNil(reviewRepository.activeQueueItems[companionKey],
                        "Re-answering correctly after undo should re-add the companion")
    }

    func test_undo_afterWrongAnswer_deletesPendingReviewRecord() async {
        // Undoing a wrong answer should delete the persisted incorrect-count record.
        // Note: a wrong answer (both sides false) is NOT "half complete" — isHalfComplete
        // requires exactly one side done — so pendingHalfCompletionCount stays 0.
        // But the pending review entry itself should be cleaned up by undo.
        let sut = makeSUT()
        let assignment = makeAssignment(id: 65, subjectID: 515)
        let subject = makeKanji(id: 515, characters: "海", meaning: "Sea", reading: "うみ")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)

        await sut.load()
        sut.userAnswer = "wrong"
        await sut.submitCurrentAnswer()

        // Wrong answer saves incorrect count to persistence, but is NOT half-complete
        // (both sides still false: isHalfComplete = hasReadings && (false != false) = false)
        XCTAssertNotNil(reviewRepository.pendingReviews[assignment.id],
                        "Wrong answer should persist incorrect count record")
        XCTAssertEqual(sut.pendingHalfCompletionCount, 0,
                       "Wrong answer alone is not a half-completion (both sides still false)")

        await sut.undo()

        XCTAssertNil(reviewRepository.pendingReviews[assignment.id],
                     "Undo should delete the pending review record when no prior progress existed")
        XCTAssertEqual(sut.pendingHalfCompletionCount, 0)
    }

    // MARK: - Fast-Forward Mode

    func test_fastForward_wrongAnswer_doesNotRequeueItem() async {
        // In fast-forward mode a wrong answer permanently discards the item —
        // it must NOT be appended back to the active queue.
        let sut = makeSUT()
        let assignment = makeAssignment(id: 66, subjectID: 516)
        let subject = makeKanji(id: 516, characters: "石", meaning: "Stone", reading: "いし")
        reviewRepository.mockAssignments = [assignment]
        reviewRepository.activeQueueItems["\(assignment.id)-Reading"] = ActiveQueueItemSnapshot(
            assignmentID: assignment.id, subjectID: subject.id,
            subjectType: "kanji", questionType: "Reading"
        )
        registerSubject(subject)

        await sut.setTimerModeEnabled(true)
        XCTAssertEqual(sut.state, .ready)
        XCTAssertEqual(sut.remainingCount, 1)

        // Wrong answer in fast-forward must NOT increase remaining count
        sut.userAnswer = "wrong"
        await sut.submitCurrentAnswer()

        XCTAssertEqual(sut.remainingCount, 1,
                       "Fast-forward wrong answer must not re-queue; remaining stays at 1 (current held)")
    }

    func test_fastForward_correctAnswer_noNewCompanionPersisted() async {
        // In fast-forward mode, answering correctly must NOT add a new companion to
        // persistence — companion auto-add is disabled in fast-forward.
        let sut = makeSUT()
        let assignment = makeAssignment(id: 67, subjectID: 517)
        let subject = makeKanji(id: 517, characters: "金", meaning: "Gold", reading: "きん")
        reviewRepository.mockAssignments = [assignment]
        // Meaning was already done; only reading companion is pending
        reviewRepository.activeQueueItems["\(assignment.id)-Reading"] = ActiveQueueItemSnapshot(
            assignmentID: assignment.id, subjectID: subject.id,
            subjectType: "kanji", questionType: "Reading"
        )
        reviewRepository.pendingReviews[assignment.id] = PendingReviewSnapshot(
            assignmentID: assignment.id, subjectID: subject.id, subjectType: "kanji",
            hasReadings: true, meaningCompleted: true, readingCompleted: false,
            incorrectMeaningAnswers: 0, incorrectReadingAnswers: 0, updatedAt: Date()
        )
        registerSubject(subject)
        reviewRepository.mockReview = makeReview(id: 103, assignmentID: 67, subjectID: 517)

        await sut.setTimerModeEnabled(true)
        XCTAssertEqual(sut.prompt?.questionType, .reading)

        // Answer reading correctly
        sut.userAnswer = "きん"
        await sut.submitCurrentAnswer()

        // The reading companion entry was deleted (answered correctly).
        // A new "Meaning" companion must NOT have been added.
        XCTAssertNil(reviewRepository.activeQueueItems["\(assignment.id)-Meaning"],
                     "No new companion should be added in fast-forward mode")
        XCTAssertNil(reviewRepository.activeQueueItems["\(assignment.id)-Reading"],
                     "Answered companion entry should be deleted from persistence")
    }

    func test_fastForward_servesCompanionItems_ignoringReadyAtStep() async {
        // Fast-forward ignores TTL delays — companion items are served immediately
        // even though they would normally require TTL steps before becoming ready.
        let sut = makeSUT(reviewTTL: 5)  // high TTL that would block normal mode
        let assignment = makeAssignment(id: 68, subjectID: 518)
        let subject = makeKanji(id: 518, characters: "銀", meaning: "Silver", reading: "ぎん")
        reviewRepository.mockAssignments = [assignment]
        reviewRepository.activeQueueItems["\(assignment.id)-Reading"] = ActiveQueueItemSnapshot(
            assignmentID: assignment.id, subjectID: subject.id,
            subjectType: "kanji", questionType: "Reading"
        )
        registerSubject(subject)

        await sut.setTimerModeEnabled(true)

        // Despite high TTL, fast-forward should immediately serve the companion
        XCTAssertEqual(sut.state, .ready)
        XCTAssertEqual(sut.prompt?.questionType, .reading,
                       "Fast-forward serves companion immediately regardless of TTL")
    }

    func test_fastForward_onlyServesCompanionItems_notUnseenQueue() async {
        // Fast-forward mode should serve only companion queue items (activeQueue),
        // never items from the unseenQueue. unseenQueue is emptied on load.
        let sut = makeSUT()
        let a1 = makeAssignment(id: 69, subjectID: 519)
        let s1 = makeKanji(id: 519, characters: "鉄", meaning: "Iron", reading: "てつ")
        let a2 = makeAssignment(id: 70, subjectID: 520)
        let s2 = makeKanji(id: 520, characters: "銅", meaning: "Copper", reading: "どう")
        reviewRepository.mockAssignments = [a1, a2]
        // Only a1 has a companion item; a2 has no companion
        reviewRepository.activeQueueItems["\(a1.id)-Reading"] = ActiveQueueItemSnapshot(
            assignmentID: a1.id, subjectID: s1.id, subjectType: "kanji", questionType: "Reading"
        )
        registerSubject(s1)
        registerSubject(s2)

        await sut.setTimerModeEnabled(true)

        // Only 1 item should be in the queue (a1's reading companion)
        // a2 has no companion entry so it should not appear in fast-forward
        XCTAssertEqual(sut.remainingCount, 1,
                       "Fast-forward should only serve items from the companion queue")
    }

    // MARK: - Companion Queue — Loading from Persistence

    func test_load_persistedCompanion_addedToActiveQueue_withTTLDelay() async {
        // A companion item from a previous session (in persistence) should be loaded
        // into the active queue with a TTL delay, not into the unseen queue.
        // With TTL=1, the companion item has readyAtStep=1 > stepCount=0 at load time,
        // meaning the first item served always comes from the unseen queue.
        let sut = makeSUT(reviewTTL: 1)
        let assignment = makeAssignment(id: 71, subjectID: 521)
        let subject = makeKanji(id: 521, characters: "東", meaning: "East", reading: "ひがし")
        reviewRepository.mockAssignments = [assignment]
        reviewRepository.activeQueueItems["\(assignment.id)-Reading"] = ActiveQueueItemSnapshot(
            assignmentID: assignment.id, subjectID: subject.id,
            subjectType: "kanji", questionType: "Reading"
        )
        registerSubject(subject)

        await sut.load()

        XCTAssertEqual(sut.state, .ready)
        // The meaning item (in unseen) + the reading companion (in active) = 2 total
        XCTAssertEqual(sut.remainingCount, 2)
        // Because of TTL=1 delay, the first item must come from the unseen queue (meaning)
        XCTAssertEqual(sut.prompt?.questionType, .meaning,
                       "Persisted companion has TTL delay; unseen item served first")
    }

    func test_load_persistedCompanion_removedFromUnseenIfPresent() async {
        // When a companion item from persistence matches a side that is still in
        // unseenQueue, it should be moved to activeQueue (not duplicated).
        // Total remaining count stays the same.
        let sut = makeSUT(reviewTTL: 0)
        let assignment = makeAssignment(id: 72, subjectID: 522)
        let subject = makeKanji(id: 522, characters: "西", meaning: "West", reading: "にし")
        reviewRepository.mockAssignments = [assignment]
        reviewRepository.activeQueueItems["\(assignment.id)-Reading"] = ActiveQueueItemSnapshot(
            assignmentID: assignment.id, subjectID: subject.id,
            subjectType: "kanji", questionType: "Reading"
        )
        registerSubject(subject)

        await sut.load()

        // 2 questions total (meaning unseen + reading moved to active) = 2
        XCTAssertEqual(sut.remainingCount, 2,
                       "Companion moved from unseen to active must not duplicate the item")
    }

    func test_load_persistedCompanion_skippedIfAssignmentNotInSession() async {
        // A companion item for an assignment that no longer appears in the session
        // (e.g. already burned) should be silently ignored.
        let sut = makeSUT()
        let assignment = makeAssignment(id: 73, subjectID: 523)
        let subject = makeKanji(id: 523, characters: "南", meaning: "South", reading: "みなみ")
        reviewRepository.mockAssignments = [assignment]
        // Companion for a DIFFERENT assignment (9999) that is not in the session
        reviewRepository.activeQueueItems["9999-Reading"] = ActiveQueueItemSnapshot(
            assignmentID: 9999, subjectID: 9999, subjectType: "kanji", questionType: "Reading"
        )
        registerSubject(subject)

        await sut.load()

        XCTAssertEqual(sut.state, .ready)
        XCTAssertEqual(sut.remainingCount, 2,
                       "Stale companion for unknown assignment should be ignored at load")
    }

    func test_load_persistedCompanion_skippedIfSideAlreadyCompleted() async {
        // A companion persistence entry for a side that is already marked as completed
        // in the pending review should not be re-served.
        let sut = makeSUT()
        let assignment = makeAssignment(id: 74, subjectID: 524)
        let subject = makeKanji(id: 524, characters: "北", meaning: "North", reading: "きた")
        reviewRepository.mockAssignments = [assignment]
        // Reading companion is persisted but reading is already done
        reviewRepository.activeQueueItems["\(assignment.id)-Reading"] = ActiveQueueItemSnapshot(
            assignmentID: assignment.id, subjectID: subject.id,
            subjectType: "kanji", questionType: "Reading"
        )
        reviewRepository.pendingReviews[assignment.id] = PendingReviewSnapshot(
            assignmentID: assignment.id, subjectID: subject.id, subjectType: "kanji",
            hasReadings: true, meaningCompleted: false, readingCompleted: true,
            incorrectMeaningAnswers: 0, incorrectReadingAnswers: 0, updatedAt: Date()
        )
        registerSubject(subject)

        await sut.load()

        // Only meaning (not done) should remain
        XCTAssertEqual(sut.remainingCount, 1)
        XCTAssertEqual(sut.prompt?.questionType, .meaning,
                       "Completed companion side must not be re-served")
    }

    // MARK: - Session Load — Error Handling

    func test_load_whenRepositoryThrows_setsFailedState() async {
        let sut = makeSUT()
        reviewRepository.error = NSError(domain: "TestError", code: -1,
                                          userInfo: [NSLocalizedDescriptionKey: "Network error"])

        await sut.load()

        if case .failed = sut.state {
            // Expected
        } else {
            XCTFail("Expected .failed state but got \(sut.state)")
        }
    }

    // MARK: - Session Load — Auto-submit Completed Reviews

    func test_load_fullyCompletedPendingReview_autoSubmittedOnLoad() async {
        // If both sides of a review are marked complete in persistence (e.g. app
        // exited after answering both but before calling next()), load should
        // auto-submit the review and preserve the stored incorrect counts.
        let sut = makeSUT()
        let assignment = makeAssignment(id: 75, subjectID: 525)
        let subject = makeKanji(id: 525, characters: "左", meaning: "Left", reading: "ひだり")
        reviewRepository.mockAssignments = [assignment]
        reviewRepository.pendingReviews[assignment.id] = PendingReviewSnapshot(
            assignmentID: assignment.id, subjectID: subject.id, subjectType: "kanji",
            hasReadings: true, meaningCompleted: true, readingCompleted: true,
            incorrectMeaningAnswers: 2, incorrectReadingAnswers: 1, updatedAt: Date()
        )
        registerSubject(subject)
        reviewRepository.mockReview = makeReview(id: 104, assignmentID: assignment.id, subjectID: subject.id)

        await sut.load()

        // Review was auto-submitted with the persisted incorrect counts
        XCTAssertEqual(reviewRepository.submitReviewCalls.count, 1,
                       "Fully-completed pending review must be auto-submitted on load")
        XCTAssertEqual(reviewRepository.submitReviewCalls[0].assignmentId, assignment.id)
        XCTAssertEqual(reviewRepository.submitReviewCalls[0].incorrectMeaningAnswers, 2)
        XCTAssertEqual(reviewRepository.submitReviewCalls[0].incorrectReadingAnswers, 1)
        // Pending review entry should be cleaned up after successful submission
        XCTAssertNil(reviewRepository.pendingReviews[assignment.id],
                     "Pending review should be deleted after successful auto-submit")
    }

    // MARK: - Remaining Count Consistency

    func test_remainingCount_decreasesAfterCorrectAnswerAndNext() async {
        // Each call to next() after a correct answer (no re-queue) should reduce
        // remainingCount by exactly 1.
        let sut = makeSUT()
        let assignment = makeAssignment(id: 77, subjectID: 527)
        let subject = makeKanji(id: 527, characters: "上", meaning: "Above", reading: "うえ")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)
        reviewRepository.mockReview = makeReview(id: 105, assignmentID: 77, subjectID: 527)

        await sut.load()
        XCTAssertEqual(sut.remainingCount, 2)

        guard let firstPrompt = sut.prompt else { XCTFail(); return }
        sut.userAnswer = firstPrompt.questionType == .meaning ? "Above" : "うえ"
        await sut.submitCurrentAnswer()
        await sut.next()

        XCTAssertEqual(sut.remainingCount, 1)

        guard let secondPrompt = sut.prompt else { XCTFail(); return }
        sut.userAnswer = secondPrompt.questionType == .meaning ? "Above" : "うえ"
        await sut.submitCurrentAnswer()
        await sut.next()

        XCTAssertEqual(sut.remainingCount, 0)
        XCTAssertEqual(sut.state, .complete)
    }

    func test_remainingCount_correctAfterWrongAnswerThenRequeue() async {
        // After a wrong answer (item re-queued) the remaining count must reflect
        // that no item was lost: old_remaining + 1 (re-queued) - 0 (current still held).
        let sut = makeSUT()
        let assignment = makeAssignment(id: 78, subjectID: 528)
        let subject = makeKanji(id: 528, characters: "下", meaning: "Below", reading: "した")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)
        reviewRepository.mockReview = makeReview(id: 106, assignmentID: 78, subjectID: 528)

        await sut.load()
        XCTAssertEqual(sut.remainingCount, 2)

        // Wrong answer → re-queued into active, count goes up by 1 (current still held)
        sut.userAnswer = "up"
        await sut.submitCurrentAnswer()
        XCTAssertEqual(sut.remainingCount, 3)

        // After next(), the re-queued item is in active, other side served → back to 2
        await sut.next()
        XCTAssertEqual(sut.remainingCount, 2)
    }

    // MARK: - Vocabulary (no readings override)

    func test_vocabulary_correctAnswer_addsReadingCompanion() async {
        // Vocabulary items have readings; companion logic should apply just like kanji.
        let sut = makeSUT()
        let assignment = makeAssignment(id: 79, subjectID: 529, type: .vocabulary)
        let subject = SubjectSnapshot(
            id: 529, object: "vocabulary", characters: "大人",
            slug: "adult", level: 5,
            meanings: [MeaningSnapshot(meaning: "Adult", primary: true, acceptedAnswer: true)],
            readings: [ReadingSnapshot(reading: "おとな", primary: true, acceptedAnswer: true, type: "kunyomi")]
        )
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)

        await sut.load()
        guard let prompt = sut.prompt else { XCTFail(); return }

        sut.userAnswer = prompt.questionType == .meaning ? "Adult" : "おとな"
        await sut.submitCurrentAnswer()

        let companionType = prompt.questionType == .meaning ? "Reading" : "Meaning"
        XCTAssertNotNil(
            reviewRepository.activeQueueItems["\(assignment.id)-\(companionType)"],
            "Vocabulary should receive companion just like kanji"
        )
    }
}

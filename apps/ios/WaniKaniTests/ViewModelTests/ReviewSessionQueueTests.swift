import XCTest
import WaniKaniCore
@testable import WaniKani

// Tests covering TTL re-queue, active queue persistence, and fast-forward mode.
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

    private func makeSUT(reviewTTL: Int = 5) -> ReviewSessionViewModel {
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

    func test_ttl_wrongAnswer_requeuedItemsIncreaseRemainingCount() async {
        // Wrong answer should re-queue BOTH sides (meaning + reading) into active.
        // A kanji starts with 2 questions. After a wrong answer, count becomes 3:
        //   current (held) + both sides re-queued (meaning + reading) - other side removed from unseen.
        // Net: 0 unseen + 2 active + 1 current = 3.
        let sut = makeSUT(reviewTTL: 0)
        let assignment = makeAssignment(id: 50, subjectID: 500)
        let subject = makeKanji(id: 500, characters: "水", meaning: "Water", reading: "すい")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)

        await sut.load()
        XCTAssertEqual(sut.remainingCount, 2)

        sut.userAnswer = "not-water"
        await sut.submitCurrentAnswer()

        // 2 active (both sides) + 1 current (held in feedback) = 3
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

    func test_ttl_withTTL1_wrongAnswerBothSidesReturnAfterOneMoreStep() async {
        // TTL=1: wrong answer enqueues both sides with readyAtStep=1.
        // After 1 more step (next()), both sides are drained from wake buckets into readyPool.
        // The session has no more unseen items, so both remaining prompts come from readyPool.
        let sut = makeSUT(reviewTTL: 1)
        let assignment = makeAssignment(id: 52, subjectID: 502)
        let subject = makeKanji(id: 502, characters: "山", meaning: "Mountain", reading: "さん")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)
        reviewRepository.mockReview = makeReview(id: 100, assignmentID: 52, subjectID: 502)

        await sut.load()
        XCTAssertEqual(sut.remainingCount, 2)

        // Answer the first prompt wrong — both sides go to active (readyAtStep=1).
        sut.userAnswer = "wrong"
        await sut.submitCurrentAnswer()
        XCTAssertEqual(sut.remainingCount, 3)  // 2 active + 1 current
        await sut.next()

        // After 1 step, both sides are ready. remainingCount = 2 (active) + 1 (current).
        // The session must still be running since there are items left.
        XCTAssertEqual(sut.state, .ready,
                       "After TTL=1 step, re-queued items become ready; session continues")
        XCTAssertEqual(sut.remainingCount, 2,
                       "Both sides in active (1 being served + 1 waiting)")
    }

    func test_ttl_withTTL2_wrongAnswerNotServedBeforeDelay() async {
        // TTL=2: after a wrong answer, BOTH sides are delayed for 2 steps.
        // After only 1 step (single next()), nothing is ready → session ends immediately.
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

        // readyAtStep = 2, stepCount after 1 advance = 1 → not ready.
        // unseenQueue is empty (other side was moved to active).
        // → session completes with nothing remaining.
        XCTAssertEqual(sut.state, .complete,
                       "Both sides delayed for 2 steps; session ends after 1 step with nothing to serve")
        XCTAssertTrue(reviewRepository.submitReviewCalls.isEmpty,
                      "Review should not be submitted since neither side was completed")
    }

    func test_ttl_multipleWrongAnswers_accumulateIncorrectCounts() async {
        // Answering the same question wrong multiple times should accumulate the
        // incorrect count. Use a radical (meaning-only) so there is only one question
        // type — no randomness between queue choices.
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

    // MARK: - Active Queue — Wrong Answer Persistence

    func test_wrongAnswer_persistsBothSides_inActiveQueue() async {
        // After a wrong answer on a kanji, BOTH sides (meaning + reading) are
        // stored in the active queue for the next session.
        let sut = makeSUT()
        let assignment = makeAssignment(id: 55, subjectID: 505)
        let subject = makeKanji(id: 505, characters: "人", meaning: "Person", reading: "ひと")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)

        await sut.load()
        let firstType = sut.prompt?.questionType

        sut.userAnswer = "wrong"
        await sut.submitCurrentAnswer()

        // Allow async persistence tasks to complete
        try? await Task.sleep(nanoseconds: 10_000_000)

        XCTAssertNotNil(
            reviewRepository.activeQueueItems["\(assignment.id)-Meaning"],
            "Meaning side should be persisted in active queue after wrong answer"
        )
        XCTAssertNotNil(
            reviewRepository.activeQueueItems["\(assignment.id)-Reading"],
            "Reading side should be persisted in active queue after wrong answer"
        )
        _ = firstType  // suppress warning
    }

    func test_wrongAnswer_radical_persistsOnlyMeaningSide() async {
        // Radicals only have a meaning question. Wrong answer should persist only
        // the meaning side (no reading side to enqueue).
        let sut = makeSUT()
        let assignment = makeAssignment(id: 56, subjectID: 506, type: .radical)
        let subject = makeRadical(id: 506, characters: "口", meaning: "Mouth")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)

        await sut.load()
        sut.userAnswer = "wrong"
        await sut.submitCurrentAnswer()

        try? await Task.sleep(nanoseconds: 10_000_000)

        XCTAssertNotNil(
            reviewRepository.activeQueueItems["\(assignment.id)-Meaning"],
            "Meaning side should be persisted after wrong answer on radical"
        )
        XCTAssertNil(
            reviewRepository.activeQueueItems["\(assignment.id)-Reading"],
            "No reading side should be persisted for a radical"
        )
    }

    func test_correctAnswer_deletesActiveQueueEntry() async {
        // When a side is answered correctly, its active queue persistence entry
        // (if any, from a previous wrong answer) is deleted.
        //
        // Uses a radical (meaning-only) with TTL=0 so the pre-seeded active item
        // lands directly in readyPool and is served deterministically as the first prompt.
        let sut = makeSUT(reviewTTL: 0)
        let assignment = makeAssignment(id: 57, subjectID: 507, type: .radical)
        let subject = makeRadical(id: 507, characters: "月", meaning: "Moon")
        reviewRepository.activeQueueItems["\(assignment.id)-Meaning"] = ActiveQueueItemSnapshot(
            assignmentID: assignment.id, subjectID: subject.id,
            subjectType: "radical", questionType: "Meaning"
        )
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)

        await sut.load()

        // With TTL=0 the active item is immediately in readyPool; unseenQueue is
        // empty (meaning was removed when the active entry was loaded). First prompt = meaning.
        XCTAssertEqual(sut.state, .ready)
        XCTAssertEqual(sut.prompt?.questionType, .meaning)

        sut.userAnswer = "Moon"
        await sut.submitCurrentAnswer()
        try? await Task.sleep(nanoseconds: 10_000_000)

        XCTAssertNil(
            reviewRepository.activeQueueItems["\(assignment.id)-Meaning"],
            "Active queue entry for correctly-answered meaning should be deleted"
        )
    }

    func test_wrongAnswer_deduped_refreshesTTL() async {
        // Answering the same side wrong twice should not create duplicate entries;
        // the readyAtStep is refreshed (deduped in activeMap).
        // With TTL=0, a deduped wrong answer stays in readyPool, not doubled.
        let sut = makeSUT(reviewTTL: 0)
        let assignment = makeAssignment(id: 58, subjectID: 508, type: .radical)
        let subject = makeRadical(id: 508, characters: "日", meaning: "Sun")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)
        reviewRepository.mockReview = makeReview(id: 102, assignmentID: 58, subjectID: 508)

        await sut.load()
        XCTAssertEqual(sut.remainingCount, 1)

        // First wrong answer
        sut.userAnswer = "wrong"
        await sut.submitCurrentAnswer()
        XCTAssertEqual(sut.remainingCount, 2)  // 1 active + 1 current
        await sut.next()

        XCTAssertEqual(sut.remainingCount, 1,
                       "After next(), de-queued item is now current; only 1 total (deduped)")
        XCTAssertEqual(sut.state, .ready)

        // Second wrong answer (same side again)
        sut.userAnswer = "wrong-again"
        await sut.submitCurrentAnswer()
        XCTAssertEqual(sut.remainingCount, 2)  // still 1 active (deduped) + 1 current
        await sut.next()

        // Correct answer
        sut.userAnswer = "Sun"
        await sut.submitCurrentAnswer()
        await sut.next()

        XCTAssertEqual(sut.state, .complete)
        guard let call = reviewRepository.submitReviewCalls.first else {
            XCTFail("Review should be submitted"); return
        }
        XCTAssertEqual(call.incorrectMeaningAnswers, 2)
    }

    func test_wrongAnswer_removesOtherSideFromUnseen() async {
        // Wrong answer moves the OTHER side out of unseenQueue into active.
        // After wrong answer + next(), the session is deterministically from active only.
        let sut = makeSUT(reviewTTL: 0)
        let assignment = makeAssignment(id: 59, subjectID: 509)
        let subject = makeKanji(id: 509, characters: "年", meaning: "Year", reading: "ねん")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)

        await sut.load()
        // Both sides start in unseen; one is served as current item.
        XCTAssertEqual(sut.remainingCount, 2)

        sut.userAnswer = "wrong"
        await sut.submitCurrentAnswer()
        await sut.next()

        // After wrong answer, other side should be in active (not unseen).
        // remainingCount = 2: 1 active (other side) + 1 current (both sides re-queued)
        // Actually both sides are in active (current was re-queued too). With TTL=0 they're
        // immediately in readyPool. One gets served as current, leaving 1 active + 1 current.
        XCTAssertEqual(sut.remainingCount, 2)
    }

    // MARK: - Active Queue — Undo

    func test_undo_afterWrongAnswer_removesActiveEntriesAndRestoresUnseen() async {
        // Undo after a wrong answer should:
        // 1. Remove both sides from the active map
        // 2. Restore the other side back to unseenQueue
        // 3. Restore stepCount to pre-answer value
        let sut = makeSUT()
        let assignment = makeAssignment(id: 60, subjectID: 510)
        let subject = makeKanji(id: 510, characters: "川", meaning: "River", reading: "かわ")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)

        await sut.load()
        let beforePrompt = sut.prompt
        let beforeRemaining = sut.remainingCount  // 2

        sut.userAnswer = "wrong"
        await sut.submitCurrentAnswer()
        // After wrong: 3 items (both active + current held)
        XCTAssertEqual(sut.remainingCount, 3)

        await sut.undo()

        XCTAssertEqual(sut.prompt, beforePrompt)
        XCTAssertEqual(sut.remainingCount, beforeRemaining)
        XCTAssertFalse(sut.canUndo)
        XCTAssertEqual(sut.phase, .answering)
    }

    func test_undo_afterWrongAnswer_deletesPendingReviewRecord() async {
        // Undoing a wrong answer should delete the persisted incorrect-count record.
        let sut = makeSUT()
        let assignment = makeAssignment(id: 61, subjectID: 511)
        let subject = makeKanji(id: 511, characters: "海", meaning: "Sea", reading: "うみ")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)

        await sut.load()
        sut.userAnswer = "wrong"
        await sut.submitCurrentAnswer()

        XCTAssertNotNil(reviewRepository.pendingReviews[assignment.id],
                        "Wrong answer should persist incorrect count record")
        XCTAssertEqual(sut.pendingHalfCompletionCount, 0)

        await sut.undo()

        XCTAssertNil(reviewRepository.pendingReviews[assignment.id],
                     "Undo should delete the pending review record when no prior progress existed")
        XCTAssertEqual(sut.pendingHalfCompletionCount, 0)
    }

    func test_undo_afterCorrectAnswer_restoresPromptAndRemainingCount() async {
        // After undoing a correct answer, the prompt and remaining count should
        // both be identical to what they were before the answer.
        let sut = makeSUT()
        let assignment = makeAssignment(id: 62, subjectID: 512)
        let subject = makeKanji(id: 512, characters: "雨", meaning: "Rain", reading: "あめ")
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

    func test_undo_afterWrongAnswer_thenReAnswerWrong_persistsBothSides() async {
        // After undoing a wrong answer and re-answering wrong, both sides
        // should again be in the active queue (dedup logic applied).
        let sut = makeSUT()
        let assignment = makeAssignment(id: 63, subjectID: 513)
        let subject = makeKanji(id: 513, characters: "花", meaning: "Flower", reading: "はな")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)

        await sut.load()
        let originalPrompt = sut.prompt

        // Wrong answer → both sides to active
        sut.userAnswer = "wrong"
        await sut.submitCurrentAnswer()

        try? await Task.sleep(nanoseconds: 10_000_000)
        XCTAssertNotNil(reviewRepository.activeQueueItems["\(assignment.id)-Meaning"])
        XCTAssertNotNil(reviewRepository.activeQueueItems["\(assignment.id)-Reading"])

        // Undo → both sides removed from active
        await sut.undo()

        try? await Task.sleep(nanoseconds: 10_000_000)
        XCTAssertNil(reviewRepository.activeQueueItems["\(assignment.id)-Meaning"])
        XCTAssertNil(reviewRepository.activeQueueItems["\(assignment.id)-Reading"])
        XCTAssertEqual(sut.prompt, originalPrompt)

        // Re-answer wrong → both sides re-added
        sut.userAnswer = "wrong-again"
        await sut.submitCurrentAnswer()

        try? await Task.sleep(nanoseconds: 10_000_000)
        XCTAssertNotNil(reviewRepository.activeQueueItems["\(assignment.id)-Meaning"],
                        "Meaning should be re-added after second wrong answer")
        XCTAssertNotNil(reviewRepository.activeQueueItems["\(assignment.id)-Reading"],
                        "Reading should be re-added after second wrong answer")
    }

    // MARK: - Fast-Forward Mode

    func test_fastForward_wrongAnswer_doesNotRequeueItem() async {
        // In fast-forward mode a wrong answer permanently discards the item —
        // it must NOT be appended back to the active queue.
        let sut = makeSUT()
        let assignment = makeAssignment(id: 64, subjectID: 514)
        let subject = makeKanji(id: 514, characters: "石", meaning: "Stone", reading: "いし")
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

    func test_fastForward_correctAnswer_deletesActiveQueueEntry() async {
        // In fast-forward mode, answering correctly should delete the active queue
        // persistence entry and not add any new entries.
        let sut = makeSUT()
        let assignment = makeAssignment(id: 65, subjectID: 515)
        let subject = makeKanji(id: 515, characters: "金", meaning: "Gold", reading: "きん")
        reviewRepository.mockAssignments = [assignment]
        // Meaning was already done; only reading active entry is pending
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
        reviewRepository.mockReview = makeReview(id: 103, assignmentID: 65, subjectID: 515)

        await sut.setTimerModeEnabled(true)
        XCTAssertEqual(sut.prompt?.questionType, .reading)

        // Answer reading correctly
        sut.userAnswer = "きん"
        await sut.submitCurrentAnswer()

        try? await Task.sleep(nanoseconds: 10_000_000)

        XCTAssertNil(reviewRepository.activeQueueItems["\(assignment.id)-Reading"],
                     "Answered active entry should be deleted from persistence")
        XCTAssertNil(reviewRepository.activeQueueItems["\(assignment.id)-Meaning"],
                     "No new active entry should be added in fast-forward mode")
    }

    func test_fastForward_servesActiveItems_ignoringReadyAtStep() async {
        // Fast-forward ignores TTL delays — active items are served immediately
        // even though they would normally require TTL steps before becoming ready.
        let sut = makeSUT(reviewTTL: 5)  // high TTL that would block normal mode
        let assignment = makeAssignment(id: 66, subjectID: 516)
        let subject = makeKanji(id: 516, characters: "銀", meaning: "Silver", reading: "ぎん")
        reviewRepository.mockAssignments = [assignment]
        reviewRepository.activeQueueItems["\(assignment.id)-Reading"] = ActiveQueueItemSnapshot(
            assignmentID: assignment.id, subjectID: subject.id,
            subjectType: "kanji", questionType: "Reading"
        )
        registerSubject(subject)

        await sut.setTimerModeEnabled(true)

        // Despite high TTL, fast-forward should immediately serve the active item
        XCTAssertEqual(sut.state, .ready)
        XCTAssertEqual(sut.prompt?.questionType, .reading,
                       "Fast-forward serves active item immediately regardless of TTL")
    }

    func test_fastForward_onlyServesActiveItems_notUnseenQueue() async {
        // Fast-forward mode should serve only active queue items,
        // never items from the unseenQueue. unseenQueue is emptied on load.
        let sut = makeSUT()
        let a1 = makeAssignment(id: 67, subjectID: 517)
        let s1 = makeKanji(id: 517, characters: "鉄", meaning: "Iron", reading: "てつ")
        let a2 = makeAssignment(id: 68, subjectID: 518)
        let s2 = makeKanji(id: 518, characters: "銅", meaning: "Copper", reading: "どう")
        reviewRepository.mockAssignments = [a1, a2]
        // Only a1 has an active item; a2 has no active entry
        reviewRepository.activeQueueItems["\(a1.id)-Reading"] = ActiveQueueItemSnapshot(
            assignmentID: a1.id, subjectID: s1.id, subjectType: "kanji", questionType: "Reading"
        )
        registerSubject(s1)
        registerSubject(s2)

        await sut.setTimerModeEnabled(true)

        // Only 1 item should be in the queue (a1's reading active entry)
        // a2 has no active entry so it should not appear in fast-forward
        XCTAssertEqual(sut.remainingCount, 1,
                       "Fast-forward should only serve items from the active queue")
    }

    // MARK: - Active Queue — Loading from Persistence

    func test_load_persistedActive_addedToActiveQueue_withTTLDelay() async {
        // An active item from a previous session (in persistence) should be loaded
        // into the active map with a TTL delay (readyAtStep = reviewTTL = 1).
        // With TTL=1, the active item has readyAtStep=1 > stepCount=0 at load time,
        // meaning the first item served always comes from the unseen queue.
        let sut = makeSUT(reviewTTL: 1)
        let assignment = makeAssignment(id: 69, subjectID: 519)
        let subject = makeKanji(id: 519, characters: "東", meaning: "East", reading: "ひがし")
        reviewRepository.mockAssignments = [assignment]
        reviewRepository.activeQueueItems["\(assignment.id)-Reading"] = ActiveQueueItemSnapshot(
            assignmentID: assignment.id, subjectID: subject.id,
            subjectType: "kanji", questionType: "Reading"
        )
        registerSubject(subject)

        await sut.load()

        XCTAssertEqual(sut.state, .ready)
        // The meaning item (in unseen) + the reading active (in wake bucket) = 2 total
        XCTAssertEqual(sut.remainingCount, 2)
        // Because of TTL=1 delay, the first item must come from the unseen queue (meaning)
        XCTAssertEqual(sut.prompt?.questionType, .meaning,
                       "Persisted active item has TTL delay; unseen item served first")
    }

    func test_load_persistedActive_removedFromUnseenIfPresent() async {
        // When an active item from persistence matches a side that is still in
        // unseenQueue, it should be moved to activeMap (not duplicated).
        // Total remaining count stays the same.
        let sut = makeSUT(reviewTTL: 0)
        let assignment = makeAssignment(id: 70, subjectID: 520)
        let subject = makeKanji(id: 520, characters: "西", meaning: "West", reading: "にし")
        reviewRepository.mockAssignments = [assignment]
        reviewRepository.activeQueueItems["\(assignment.id)-Reading"] = ActiveQueueItemSnapshot(
            assignmentID: assignment.id, subjectID: subject.id,
            subjectType: "kanji", questionType: "Reading"
        )
        registerSubject(subject)

        await sut.load()

        // 2 questions total (meaning unseen + reading moved to active) = 2
        XCTAssertEqual(sut.remainingCount, 2,
                       "Active item moved from unseen to active must not duplicate the item")
    }

    func test_load_persistedActive_skippedIfAssignmentNotInSession() async {
        // An active item for an assignment that no longer appears in the session
        // (e.g. already burned) should be silently ignored.
        let sut = makeSUT()
        let assignment = makeAssignment(id: 71, subjectID: 521)
        let subject = makeKanji(id: 521, characters: "南", meaning: "South", reading: "みなみ")
        reviewRepository.mockAssignments = [assignment]
        // Active entry for a DIFFERENT assignment (9999) that is not in the session
        reviewRepository.activeQueueItems["9999-Reading"] = ActiveQueueItemSnapshot(
            assignmentID: 9999, subjectID: 9999, subjectType: "kanji", questionType: "Reading"
        )
        registerSubject(subject)

        await sut.load()

        XCTAssertEqual(sut.state, .ready)
        XCTAssertEqual(sut.remainingCount, 2,
                       "Stale active entry for unknown assignment should be ignored at load")
    }

    func test_load_persistedActive_skippedIfSideAlreadyCompleted() async {
        // An active persistence entry for a side that is already marked as completed
        // in the pending review should not be re-served.
        let sut = makeSUT()
        let assignment = makeAssignment(id: 72, subjectID: 522)
        let subject = makeKanji(id: 522, characters: "北", meaning: "North", reading: "きた")
        reviewRepository.mockAssignments = [assignment]
        // Reading active is persisted but reading is already done
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
                       "Completed active side must not be re-served")
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
        let assignment = makeAssignment(id: 73, subjectID: 523)
        let subject = makeKanji(id: 523, characters: "左", meaning: "Left", reading: "ひだり")
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
        let assignment = makeAssignment(id: 74, subjectID: 524)
        let subject = makeKanji(id: 524, characters: "上", meaning: "Above", reading: "うえ")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)
        reviewRepository.mockReview = makeReview(id: 105, assignmentID: 74, subjectID: 524)

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
        // After a wrong answer (both sides re-queued) the remaining count must
        // reflect that no item was lost:
        //   0 unseen + 2 active + 1 current = 3
        let sut = makeSUT()
        let assignment = makeAssignment(id: 75, subjectID: 525)
        let subject = makeKanji(id: 525, characters: "下", meaning: "Below", reading: "した")
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)
        reviewRepository.mockReview = makeReview(id: 106, assignmentID: 75, subjectID: 525)

        await sut.load()
        XCTAssertEqual(sut.remainingCount, 2)

        // Wrong answer → both sides re-queued, other side removed from unseen
        sut.userAnswer = "up"
        await sut.submitCurrentAnswer()
        XCTAssertEqual(sut.remainingCount, 3)  // 2 active + 1 current

        // After next(), one active item is served → 1 active + 1 current
        await sut.next()
        XCTAssertEqual(sut.remainingCount, 2)
    }

    // MARK: - Vocabulary (with readings)

    func test_vocabulary_wrongAnswer_enqueueBothSides() async {
        // Vocabulary items have readings; wrong answer should enqueue both sides.
        let sut = makeSUT()
        let assignment = makeAssignment(id: 76, subjectID: 526, type: .vocabulary)
        let subject = SubjectSnapshot(
            id: 526, object: "vocabulary", characters: "大人",
            slug: "adult", level: 5,
            meanings: [MeaningSnapshot(meaning: "Adult", primary: true, acceptedAnswer: true)],
            readings: [ReadingSnapshot(reading: "おとな", primary: true, acceptedAnswer: true, type: "kunyomi")]
        )
        reviewRepository.mockAssignments = [assignment]
        registerSubject(subject)

        await sut.load()
        sut.userAnswer = "wrong"
        await sut.submitCurrentAnswer()

        try? await Task.sleep(nanoseconds: 10_000_000)

        XCTAssertNotNil(reviewRepository.activeQueueItems["\(assignment.id)-Meaning"],
                        "Meaning side should be in active queue after wrong answer on vocabulary")
        XCTAssertNotNil(reviewRepository.activeQueueItems["\(assignment.id)-Reading"],
                        "Reading side should be in active queue after wrong answer on vocabulary")
    }
}

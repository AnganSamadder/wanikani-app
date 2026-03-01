import XCTest
import WaniKaniCore
@testable import WaniKani

@MainActor
final class ReviewSessionViewModelTests: XCTestCase {
    private var reviewRepository: MockReviewSessionRepository!
    private var subjectRepository: MockSubjectDetailRepository!
    private var subjectRelationsRepository: MockSubjectRelationsRepository!
    private var studyMaterialRepository: MockStudyMaterialRepository!
    private var sut: ReviewSessionViewModel!

    override func setUp() {
        super.setUp()
        reviewRepository = MockReviewSessionRepository()
        subjectRepository = MockSubjectDetailRepository()
        subjectRelationsRepository = MockSubjectRelationsRepository()
        studyMaterialRepository = MockStudyMaterialRepository()
        sut = ReviewSessionViewModel(
            reviewSessionRepository: reviewRepository,
            subjectDetailRepository: subjectRepository,
            subjectRelationsRepository: subjectRelationsRepository,
            studyMaterialRepository: studyMaterialRepository,
            reviewTTL: 0
        )
    }

    override func tearDown() {
        sut = nil
        reviewRepository = nil
        subjectRepository = nil
        subjectRelationsRepository = nil
        studyMaterialRepository = nil
        super.tearDown()
    }

    func test_load_whenNoAssignments_setsEmptyState() async {
        reviewRepository.mockAssignments = []

        await sut.load()

        XCTAssertEqual(sut.state, .empty)
        XCTAssertNil(sut.prompt)
    }

    func test_load_andSubmitCorrectAnswers_completesSession() async {
        let assignment = AssignmentSnapshot(
            id: 1,
            subjectID: 100,
            subjectType: .kanji,
            srsStage: 1,
            availableAt: Date(),
            unlockedAt: Date(),
            startedAt: Date(),
            passedAt: nil,
            burnedAt: nil,
            hidden: false
        )

        let subject = SubjectSnapshot(
            id: 100,
            object: "kanji",
            characters: "部",
            slug: "part",
            level: 1,
            meanings: [MeaningSnapshot(meaning: "Part", primary: true, acceptedAnswer: true)],
            readings: [ReadingSnapshot(reading: "ぶ", primary: true, acceptedAnswer: true)]
        )

        reviewRepository.mockAssignments = [assignment]
        subjectRepository.subjectsByID = [100: subject]
        reviewRepository.mockReview = Review(
            id: 1,
            object: "review",
            url: "",
            dataUpdatedAt: nil,
            data: ReviewData(
                createdAt: Date(),
                assignmentID: 1,
                subjectID: 100,
                spacedRepetitionSystemID: 1,
                startingSRSStage: 1,
                endingSRSStage: 2,
                incorrectMeaningAnswers: 0,
                incorrectReadingAnswers: 0
            )
        )

        await sut.load()

        XCTAssertEqual(sut.state, .ready)
        XCTAssertEqual(sut.remainingCount, 2)

        var iterations = 0
        while sut.state == .ready && iterations < 6 {
            iterations += 1

            guard let prompt = sut.prompt else {
                XCTFail("Expected active prompt")
                return
            }

            if prompt.questionType == .meaning {
                sut.userAnswer = "Part"
            } else {
                sut.userAnswer = "ぶ"
            }

            await sut.submitCurrentAnswer()
            XCTAssertEqual(sut.phase, .feedback)
            await sut.next()
        }

        XCTAssertLessThanOrEqual(iterations, 6)
        XCTAssertEqual(sut.state, .complete)
        XCTAssertEqual(sut.remainingCount, 0)
        XCTAssertNil(sut.prompt)
    }

    func test_submitFirstSide_persistsHalfCompletion() async {
        let assignment = AssignmentSnapshot(
            id: 10,
            subjectID: 200,
            subjectType: .kanji,
            srsStage: 1,
            availableAt: Date(),
            unlockedAt: Date(),
            startedAt: Date(),
            passedAt: nil,
            burnedAt: nil,
            hidden: false
        )
        let subject = SubjectSnapshot(
            id: 200,
            object: "kanji",
            characters: "言",
            slug: "say",
            level: 1,
            meanings: [MeaningSnapshot(meaning: "Say", primary: true, acceptedAnswer: true)],
            readings: [ReadingSnapshot(reading: "げん", primary: true, acceptedAnswer: true, type: "onyomi")]
        )

        reviewRepository.mockAssignments = [assignment]
        subjectRepository.subjectsByID = [200: subject]

        await sut.load()
        guard let prompt = sut.prompt else {
            XCTFail("Expected prompt")
            return
        }

        sut.userAnswer = prompt.questionType == .meaning ? "Say" : "げん"
        await sut.submitCurrentAnswer()

        XCTAssertEqual(sut.pendingHalfCompletionCount, 1)
        XCTAssertEqual(reviewRepository.pendingReviews[assignment.id]?.isHalfComplete, true)
    }

    func test_load_fetchesSubjectsInSingleBatch() async {
        let assignmentOne = AssignmentSnapshot(
            id: 21,
            subjectID: 401,
            subjectType: .kanji,
            srsStage: 1,
            availableAt: Date(),
            unlockedAt: Date(),
            startedAt: Date(),
            passedAt: nil,
            burnedAt: nil,
            hidden: false
        )
        let assignmentTwo = AssignmentSnapshot(
            id: 22,
            subjectID: 402,
            subjectType: .vocabulary,
            srsStage: 1,
            availableAt: Date(),
            unlockedAt: Date(),
            startedAt: Date(),
            passedAt: nil,
            burnedAt: nil,
            hidden: false
        )
        let subjectOne = SubjectSnapshot(
            id: 401,
            object: "kanji",
            characters: "林",
            slug: "woods",
            level: 1,
            meanings: [MeaningSnapshot(meaning: "Woods", primary: true, acceptedAnswer: true)],
            readings: [ReadingSnapshot(reading: "りん", primary: true, acceptedAnswer: true, type: "onyomi")]
        )
        let subjectTwo = SubjectSnapshot(
            id: 402,
            object: "vocabulary",
            characters: "木",
            slug: "tree",
            level: 1,
            meanings: [MeaningSnapshot(meaning: "Tree", primary: true, acceptedAnswer: true)],
            readings: [ReadingSnapshot(reading: "き", primary: true, acceptedAnswer: true, type: "kunyomi")]
        )

        reviewRepository.mockAssignments = [assignmentOne, assignmentTwo]
        subjectRepository.subjectsByID = [401: subjectOne, 402: subjectTwo]
        subjectRelationsRepository.subjectsByID = [401: subjectOne, 402: subjectTwo]

        await sut.load()

        XCTAssertEqual(subjectRelationsRepository.fetchSubjectDetailsCalls.count, 1)
        XCTAssertEqual(Set(subjectRelationsRepository.fetchSubjectDetailsCalls[0]), Set([401, 402]))
        XCTAssertTrue(subjectRepository.fetchSubjectDetailCalls.isEmpty)
        XCTAssertEqual(sut.state, .ready)
    }

    func test_load_whenCalledConcurrently_onlyStartsSessionOnce() async {
        let assignment = AssignmentSnapshot(
            id: 23,
            subjectID: 403,
            subjectType: .kanji,
            srsStage: 1,
            availableAt: Date(),
            unlockedAt: Date(),
            startedAt: Date(),
            passedAt: nil,
            burnedAt: nil,
            hidden: false
        )
        let subject = SubjectSnapshot(
            id: 403,
            object: "kanji",
            characters: "森",
            slug: "forest",
            level: 1,
            meanings: [MeaningSnapshot(meaning: "Forest", primary: true, acceptedAnswer: true)],
            readings: [ReadingSnapshot(reading: "もり", primary: true, acceptedAnswer: true, type: "kunyomi")]
        )
        reviewRepository.mockAssignments = [assignment]
        reviewRepository.startReviewSessionDelayNanoseconds = 50_000_000
        subjectRepository.subjectsByID = [403: subject]
        subjectRelationsRepository.subjectsByID = [403: subject]

        async let firstLoad: Void = sut.load()
        async let secondLoad: Void = sut.load()
        _ = await (firstLoad, secondLoad)

        XCTAssertEqual(reviewRepository.startReviewSessionCallCount, 1)
        XCTAssertEqual(subjectRelationsRepository.fetchSubjectDetailsCalls.count, 1)
        XCTAssertEqual(sut.state, .ready)
    }

    func test_load_finishPendingOnly_queuesOnlyMissingSide() async {
        let assignment = AssignmentSnapshot(
            id: 11,
            subjectID: 201,
            subjectType: .kanji,
            srsStage: 1,
            availableAt: Date(),
            unlockedAt: Date(),
            startedAt: Date(),
            passedAt: nil,
            burnedAt: nil,
            hidden: false
        )
        let subject = SubjectSnapshot(
            id: 201,
            object: "kanji",
            characters: "学",
            slug: "study",
            level: 1,
            meanings: [MeaningSnapshot(meaning: "Study", primary: true, acceptedAnswer: true)],
            readings: [ReadingSnapshot(reading: "がく", primary: true, acceptedAnswer: true, type: "onyomi")]
        )
        reviewRepository.mockAssignments = [assignment]
        // Meaning is done, reading is missing — companion queue tracks the pending side
        reviewRepository.pendingReviews[assignment.id] = PendingReviewSnapshot(
            assignmentID: assignment.id,
            subjectID: assignment.subjectID,
            subjectType: assignment.subjectType.rawValue,
            hasReadings: true,
            meaningCompleted: true,
            readingCompleted: false,
            incorrectMeaningAnswers: 1,
            incorrectReadingAnswers: 0,
            updatedAt: Date()
        )
        reviewRepository.activeQueueItems["\(assignment.id)-Reading"] = ActiveQueueItemSnapshot(
            assignmentID: assignment.id,
            subjectID: assignment.subjectID,
            subjectType: assignment.subjectType.rawValue,
            questionType: "Reading"
        )
        subjectRepository.subjectsByID = [201: subject]
        subjectRelationsRepository.subjectsByID = [201: subject]

        await sut.load(policy: .finishPendingOnly)

        XCTAssertEqual(sut.state, .ready)
        XCTAssertEqual(sut.prompt?.questionType, .reading)
        XCTAssertEqual(sut.remainingCount, 1)
    }

    func test_finishPendingMode_whenQueueDrains_navigatesDashboard() async {
        let assignment = AssignmentSnapshot(
            id: 12,
            subjectID: 202,
            subjectType: .kanji,
            srsStage: 1,
            availableAt: Date(),
            unlockedAt: Date(),
            startedAt: Date(),
            passedAt: nil,
            burnedAt: nil,
            hidden: false
        )
        let subject = SubjectSnapshot(
            id: 202,
            object: "kanji",
            characters: "校",
            slug: "school",
            level: 1,
            meanings: [MeaningSnapshot(meaning: "School", primary: true, acceptedAnswer: true)],
            readings: [ReadingSnapshot(reading: "こう", primary: true, acceptedAnswer: true, type: "onyomi")]
        )
        reviewRepository.mockAssignments = [assignment]
        reviewRepository.pendingReviews[assignment.id] = PendingReviewSnapshot(
            assignmentID: assignment.id,
            subjectID: assignment.subjectID,
            subjectType: assignment.subjectType.rawValue,
            hasReadings: true,
            meaningCompleted: true,
            readingCompleted: false,
            incorrectMeaningAnswers: 0,
            incorrectReadingAnswers: 0,
            updatedAt: Date()
        )
        reviewRepository.activeQueueItems["\(assignment.id)-Reading"] = ActiveQueueItemSnapshot(
            assignmentID: assignment.id,
            subjectID: assignment.subjectID,
            subjectType: assignment.subjectType.rawValue,
            questionType: "Reading"
        )
        subjectRepository.subjectsByID = [202: subject]
        subjectRelationsRepository.subjectsByID = [202: subject]
        reviewRepository.mockReview = Review(
            id: 2,
            object: "review",
            url: "",
            dataUpdatedAt: nil,
            data: ReviewData(
                createdAt: Date(),
                assignmentID: assignment.id,
                subjectID: assignment.subjectID,
                spacedRepetitionSystemID: 1,
                startingSRSStage: 1,
                endingSRSStage: 2,
                incorrectMeaningAnswers: 0,
                incorrectReadingAnswers: 0
            )
        )

        await sut.setTimerModeEnabled(true)
        XCTAssertEqual(sut.prompt?.questionType, .reading)

        sut.userAnswer = "こう"
        await sut.submitCurrentAnswer()
        await sut.next()

        XCTAssertEqual(sut.navigateToTab, .dashboard)
        XCTAssertEqual(sut.pendingHalfCompletionCount, 0)
    }

    func test_radicalCompletion_doesNotPersistPendingReview() async {
        let assignment = AssignmentSnapshot(
            id: 13,
            subjectID: 203,
            subjectType: .radical,
            srsStage: 1,
            availableAt: Date(),
            unlockedAt: Date(),
            startedAt: Date(),
            passedAt: nil,
            burnedAt: nil,
            hidden: false
        )
        let subject = SubjectSnapshot(
            id: 203,
            object: "radical",
            characters: "言",
            slug: "speech",
            level: 1,
            meanings: [MeaningSnapshot(meaning: "Speech", primary: true, acceptedAnswer: true)],
            readings: []
        )
        reviewRepository.mockAssignments = [assignment]
        subjectRepository.subjectsByID = [203: subject]
        reviewRepository.mockReview = Review(
            id: 3,
            object: "review",
            url: "",
            dataUpdatedAt: nil,
            data: ReviewData(
                createdAt: Date(),
                assignmentID: assignment.id,
                subjectID: assignment.subjectID,
                spacedRepetitionSystemID: 1,
                startingSRSStage: 1,
                endingSRSStage: 2,
                incorrectMeaningAnswers: 0,
                incorrectReadingAnswers: 0
            )
        )

        await sut.load()
        sut.userAnswer = "Speech"
        await sut.submitCurrentAnswer()

        XCTAssertTrue(reviewRepository.pendingReviews.isEmpty)
    }

    func test_load_withPersistedHalfCompletion_restoresMissingSideOnly() async {
        let assignment = AssignmentSnapshot(
            id: 14,
            subjectID: 204,
            subjectType: .kanji,
            srsStage: 1,
            availableAt: Date(),
            unlockedAt: Date(),
            startedAt: Date(),
            passedAt: nil,
            burnedAt: nil,
            hidden: false
        )
        let subject = SubjectSnapshot(
            id: 204,
            object: "kanji",
            characters: "行",
            slug: "go",
            level: 1,
            meanings: [MeaningSnapshot(meaning: "Go", primary: true, acceptedAnswer: true)],
            readings: [ReadingSnapshot(reading: "こう", primary: true, acceptedAnswer: true, type: "onyomi")]
        )
        reviewRepository.mockAssignments = [assignment]
        reviewRepository.pendingReviews[assignment.id] = PendingReviewSnapshot(
            assignmentID: assignment.id,
            subjectID: assignment.subjectID,
            subjectType: assignment.subjectType.rawValue,
            hasReadings: true,
            meaningCompleted: false,
            readingCompleted: true,
            incorrectMeaningAnswers: 0,
            incorrectReadingAnswers: 1,
            updatedAt: Date()
        )
        subjectRepository.subjectsByID = [204: subject]

        await sut.load()

        XCTAssertEqual(sut.state, .ready)
        XCTAssertEqual(sut.prompt?.questionType, .meaning)
        XCTAssertEqual(sut.remainingCount, 1)
    }

    func test_submitUndoNext_pendingHalfCompletionCountUpdatesLive() async {
        let assignment = AssignmentSnapshot(
            id: 15,
            subjectID: 205,
            subjectType: .kanji,
            srsStage: 1,
            availableAt: Date(),
            unlockedAt: Date(),
            startedAt: Date(),
            passedAt: nil,
            burnedAt: nil,
            hidden: false
        )
        let subject = SubjectSnapshot(
            id: 205,
            object: "kanji",
            characters: "山",
            slug: "mountain",
            level: 1,
            meanings: [MeaningSnapshot(meaning: "Mountain", primary: true, acceptedAnswer: true)],
            readings: [ReadingSnapshot(reading: "さん", primary: true, acceptedAnswer: true, type: "onyomi")]
        )
        reviewRepository.mockAssignments = [assignment]
        subjectRepository.subjectsByID = [205: subject]
        reviewRepository.mockReview = Review(
            id: 4,
            object: "review",
            url: "",
            dataUpdatedAt: nil,
            data: ReviewData(
                createdAt: Date(),
                assignmentID: assignment.id,
                subjectID: assignment.subjectID,
                spacedRepetitionSystemID: 1,
                startingSRSStage: 1,
                endingSRSStage: 2,
                incorrectMeaningAnswers: 0,
                incorrectReadingAnswers: 0
            )
        )

        await sut.load()

        // First side completion should create one half-completion.
        if sut.prompt?.questionType == .meaning {
            sut.userAnswer = "Mountain"
        } else {
            sut.userAnswer = "さん"
        }
        await sut.submitCurrentAnswer()
        XCTAssertEqual(sut.pendingHalfCompletionCount, 1)

        // Undo should remove persisted progress for this untouched item.
        await sut.undo()
        XCTAssertEqual(sut.pendingHalfCompletionCount, 0)

        // Submit again and move to second side.
        if sut.prompt?.questionType == .meaning {
            sut.userAnswer = "Mountain"
        } else {
            sut.userAnswer = "さん"
        }
        await sut.submitCurrentAnswer()
        XCTAssertEqual(sut.pendingHalfCompletionCount, 1)
        await sut.next()
        XCTAssertEqual(sut.pendingHalfCompletionCount, 1)

        // Finishing second side should make half-completion count drop to 0.
        if sut.prompt?.questionType == .meaning {
            sut.userAnswer = "Mountain"
        } else {
            sut.userAnswer = "さん"
        }
        await sut.submitCurrentAnswer()
        XCTAssertEqual(sut.pendingHalfCompletionCount, 0)
    }

    func test_submit_completeItem_defersCommitUntilNext() async {
        let assignment = AssignmentSnapshot(
            id: 16,
            subjectID: 206,
            subjectType: .kanji,
            srsStage: 1,
            availableAt: Date(),
            unlockedAt: Date(),
            startedAt: Date(),
            passedAt: nil,
            burnedAt: nil,
            hidden: false
        )
        let subject = SubjectSnapshot(
            id: 206,
            object: "kanji",
            characters: "川",
            slug: "river",
            level: 1,
            meanings: [MeaningSnapshot(meaning: "River", primary: true, acceptedAnswer: true)],
            readings: [ReadingSnapshot(reading: "かわ", primary: true, acceptedAnswer: true, type: "kunyomi")]
        )
        reviewRepository.mockAssignments = [assignment]
        subjectRepository.subjectsByID = [206: subject]
        reviewRepository.mockReview = Review(
            id: 5,
            object: "review",
            url: "",
            dataUpdatedAt: nil,
            data: ReviewData(
                createdAt: Date(),
                assignmentID: assignment.id,
                subjectID: assignment.subjectID,
                spacedRepetitionSystemID: 1,
                startingSRSStage: 1,
                endingSRSStage: 2,
                incorrectMeaningAnswers: 0,
                incorrectReadingAnswers: 0
            )
        )

        await sut.load()
        XCTAssertEqual(reviewRepository.submitReviewCalls.count, 0)

        for _ in 0..<2 {
            guard sut.state == .ready else {
                XCTFail("Expected ready state while answering both sides")
                return
            }
            if sut.prompt?.questionType == .meaning {
                sut.userAnswer = "River"
            } else {
                sut.userAnswer = "かわ"
            }
            await sut.submitCurrentAnswer()
            XCTAssertEqual(reviewRepository.submitReviewCalls.count, 0)
            await sut.next()
        }

        XCTAssertEqual(reviewRepository.submitReviewCalls.count, 1)
        XCTAssertEqual(reviewRepository.submitReviewCalls.first?.assignmentId, assignment.id)
    }

    func test_restart_afterIncorrectAnswer_preservesIncorrectCountsForFinalSubmit() async {
        let assignment = AssignmentSnapshot(
            id: 17,
            subjectID: 207,
            subjectType: .kanji,
            srsStage: 1,
            availableAt: Date(),
            unlockedAt: Date(),
            startedAt: Date(),
            passedAt: nil,
            burnedAt: nil,
            hidden: false
        )
        let subject = SubjectSnapshot(
            id: 207,
            object: "kanji",
            characters: "海",
            slug: "sea",
            level: 1,
            meanings: [MeaningSnapshot(meaning: "Sea", primary: true, acceptedAnswer: true)],
            readings: [ReadingSnapshot(reading: "うみ", primary: true, acceptedAnswer: true, type: "kunyomi")]
        )
        reviewRepository.mockAssignments = [assignment]
        subjectRepository.subjectsByID = [207: subject]
        reviewRepository.mockReview = Review(
            id: 6,
            object: "review",
            url: "",
            dataUpdatedAt: nil,
            data: ReviewData(
                createdAt: Date(),
                assignmentID: assignment.id,
                subjectID: assignment.subjectID,
                spacedRepetitionSystemID: 1,
                startingSRSStage: 1,
                endingSRSStage: 2,
                incorrectMeaningAnswers: 0,
                incorrectReadingAnswers: 0
            )
        )

        await sut.load()
        sut.userAnswer = "definitely-wrong"
        await sut.submitCurrentAnswer()

        guard let persisted = reviewRepository.pendingReviews[assignment.id] else {
            XCTFail("Expected pending review to be persisted")
            return
        }
        XCTAssertEqual(persisted.incorrectMeaningAnswers + persisted.incorrectReadingAnswers, 1)

        // Simulate process restart with same repositories/persistence state.
        sut = ReviewSessionViewModel(
            reviewSessionRepository: reviewRepository,
            subjectDetailRepository: subjectRepository,
            subjectRelationsRepository: subjectRelationsRepository,
            studyMaterialRepository: studyMaterialRepository,
            reviewTTL: 0
        )

        await sut.load()

        var safety = 0
        while sut.state == .ready && safety < 6 {
            safety += 1
            if sut.prompt?.questionType == .meaning {
                sut.userAnswer = "Sea"
            } else {
                sut.userAnswer = "うみ"
            }
            await sut.submitCurrentAnswer()
            await sut.next()
        }

        XCTAssertEqual(reviewRepository.submitReviewCalls.count, 1)
        XCTAssertEqual(reviewRepository.submitReviewCalls[0].incorrectMeaningAnswers, persisted.incorrectMeaningAnswers)
        XCTAssertEqual(reviewRepository.submitReviewCalls[0].incorrectReadingAnswers, persisted.incorrectReadingAnswers)
    }

    func test_undo_restoresPromptAndClearsLatestAttempt() async {
        let assignment = AssignmentSnapshot(
            id: 18,
            subjectID: 208,
            subjectType: .kanji,
            srsStage: 1,
            availableAt: Date(),
            unlockedAt: Date(),
            startedAt: Date(),
            passedAt: nil,
            burnedAt: nil,
            hidden: false
        )
        let subject = SubjectSnapshot(
            id: 208,
            object: "kanji",
            characters: "火",
            slug: "fire",
            level: 1,
            meanings: [MeaningSnapshot(meaning: "Fire", primary: true, acceptedAnswer: true)],
            readings: [ReadingSnapshot(reading: "ひ", primary: true, acceptedAnswer: true, type: "kunyomi")]
        )
        reviewRepository.mockAssignments = [assignment]
        subjectRepository.subjectsByID = [208: subject]

        await sut.load()
        let originalPrompt = sut.prompt
        if sut.prompt?.questionType == .meaning {
            sut.userAnswer = "Fire"
        } else {
            sut.userAnswer = "ひ"
        }
        await sut.submitCurrentAnswer()

        XCTAssertEqual(sut.phase, .feedback)
        XCTAssertEqual(sut.attemptHistory.count, 1)
        XCTAssertTrue(sut.canUndo)

        await sut.undo()

        XCTAssertEqual(sut.phase, .answering)
        XCTAssertEqual(sut.attemptHistory.count, 0)
        XCTAssertFalse(sut.canUndo)
        XCTAssertEqual(sut.prompt, originalPrompt)
    }
}

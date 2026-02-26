import XCTest
import WaniKaniCore
@testable import WaniKani

@MainActor
final class ReviewSessionViewModelTests: XCTestCase {
    private var reviewRepository: MockReviewSessionRepository!
    private var subjectRepository: MockSubjectDetailRepository!
    private var sut: ReviewSessionViewModel!

    override func setUp() {
        super.setUp()
        reviewRepository = MockReviewSessionRepository()
        subjectRepository = MockSubjectDetailRepository()
        sut = ReviewSessionViewModel(
            reviewSessionRepository: reviewRepository,
            subjectDetailRepository: subjectRepository
        )
    }

    override func tearDown() {
        sut = nil
        reviewRepository = nil
        subjectRepository = nil
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
}

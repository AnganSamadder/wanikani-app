import XCTest
import WaniKaniCore
@testable import WaniKani

@MainActor
final class LessonSessionViewModelTests: XCTestCase {
    private var repository: MockLessonSessionRepository!
    private var sut: LessonSessionViewModel!

    override func setUp() {
        super.setUp()
        repository = MockLessonSessionRepository()
        sut = LessonSessionViewModel(repository: repository)
    }

    override func tearDown() {
        sut = nil
        repository = nil
        super.tearDown()
    }

    func test_load_whenQueueEmpty_setsEmptyState() async {
        repository.mockQueue = []

        await sut.load()

        XCTAssertEqual(sut.state, .empty)
    }

    func test_quizFlow_whenAnswersCorrect_completesSession() async {
        repository.mockQueue = [
            SubjectSnapshot(
                id: 100,
                object: "kanji",
                characters: "部",
                slug: "part",
                level: 1,
                meanings: [MeaningSnapshot(meaning: "Part", primary: true, acceptedAnswer: true)],
                readings: [ReadingSnapshot(reading: "ぶ", primary: true, acceptedAnswer: true)]
            )
        ]

        await sut.load()
        XCTAssertEqual(sut.state, .studying)

        sut.startQuiz()
        XCTAssertEqual(sut.state, .quizzing)

        sut.userAnswer = "Part"
        sut.submitCurrentAnswer()
        XCTAssertEqual(sut.questionLabel, "Reading")

        sut.userAnswer = "ぶ"
        sut.submitCurrentAnswer()

        XCTAssertEqual(sut.state, .complete)
    }
}

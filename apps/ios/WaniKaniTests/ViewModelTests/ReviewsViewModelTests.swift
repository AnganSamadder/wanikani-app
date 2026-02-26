import XCTest
import WaniKaniCore
@testable import WaniKani

@MainActor
final class ReviewsViewModelTests: XCTestCase {
    var sut: ReviewsViewModel!
    var assignmentRepo: MockAssignmentRepository!
    var subjectRepo: MockSubjectRepository!
    var reviewRepo: MockReviewRepository!

    override func setUp() {
        super.setUp()
        assignmentRepo = MockAssignmentRepository()
        subjectRepo = MockSubjectRepository()
        reviewRepo = MockReviewRepository()
        sut = ReviewsViewModel(
            assignmentRepo: assignmentRepo,
            subjectRepo: subjectRepo,
            reviewRepo: reviewRepo
        )
    }

    override func tearDown() {
        sut = nil
        assignmentRepo = nil
        subjectRepo = nil
        reviewRepo = nil
        super.tearDown()
    }
    
    func test_loadReviews_empty_setsStateToEmpty() async {
        assignmentRepo.mockAssignments = []
        
        await sut.loadReviews()
        
        if case .empty = sut.state {
            // Success
        } else {
            XCTFail("Expected .empty state, got \(sut.state)")
        }
    }
    
    func test_loadReviews_valid_setsStateToReviewing() async {
        let assignment = AssignmentSnapshot.mock(id: 1, subjectID: 100)
        let subject = SubjectSnapshot.mock(id: 100)
        
        assignmentRepo.mockAssignments = [assignment]
        subjectRepo.mockSubject = subject
        
        await sut.loadReviews()
        
        if case .reviewing = sut.state {
            XCTAssertNotNil(sut.currentItem)
            XCTAssertEqual(sut.currentItem?.subject.id, 100)
            // One for meaning, one for reading (since it's a kanji)
            // Total queue size should be 1 after removing currentItem
            XCTAssertEqual(sut.queue.count, 1) 
        } else {
            XCTFail("Expected .reviewing state, got \(sut.state)")
        }
    }
    
    func test_loadReviews_error_setsStateToError() async {
        assignmentRepo.error = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        await sut.loadReviews()
        
        if case .error(let message) = sut.state {
            XCTAssertEqual(message, "Network error")
        } else {
            XCTFail("Expected .error state, got \(sut.state)")
        }
    }
    
    func test_submitAnswer_advancesToNext() async {
        let assignment = AssignmentSnapshot.mock(id: 1, subjectID: 100)
        let subject = SubjectSnapshot.mock(id: 100)
        
        // Setup mock review response
        let mockReview = Review(
            id: 0,
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
        reviewRepo.mockReview = mockReview
        
        assignmentRepo.mockAssignments = [assignment]
        subjectRepo.mockSubject = subject
        
        await sut.loadReviews()
        
        let firstItem = sut.currentItem
        XCTAssertNotNil(firstItem)
        
        // Answer the first question correctly (could be meaning or reading due to shuffling)
        let firstQuestionType = firstItem?.questionType
        let firstAnswer = firstQuestionType == .meaning ? "Test" : "test"
        await sut.submitAnswer(firstAnswer)
        
        // Should advance to the other question type for the same assignment
        let secondItem = sut.currentItem
        XCTAssertNotNil(secondItem)
        XCTAssertEqual(secondItem?.assignment.id, assignment.id)
        XCTAssertNotEqual(secondItem?.questionType, firstQuestionType)
        
        // Answer the second question correctly
        let secondAnswer = secondItem?.questionType == .meaning ? "Test" : "test"
        await sut.submitAnswer(secondAnswer)
        
        // After both parts complete, review is submitted and assignment removed from queue
        // With only one assignment, queue should be empty and state should be complete
        if case .complete = sut.state {
            // Success - session complete
        } else {
            // Might still be reviewing if queue isn't empty, but currentItem should be nil
            XCTAssertNil(sut.currentItem, "Expected nil currentItem after completing both questions")
        }
    }
}

// MARK: - Mocks & Helpers

extension AssignmentSnapshot {
    static func mock(id: Int, subjectID: Int, subjectType: SubjectType = .kanji) -> AssignmentSnapshot {
        AssignmentSnapshot(
            id: id,
            subjectID: subjectID,
            subjectType: subjectType,
            srsStage: 1,
            availableAt: Date(),
            unlockedAt: Date(),
            startedAt: nil,
            passedAt: nil,
            burnedAt: nil,
            hidden: false
        )
    }
}

extension SubjectSnapshot {
    static func mock(id: Int, object: String = "kanji", characters: String = "漢") -> SubjectSnapshot {
        SubjectSnapshot(
            id: id,
            object: object,
            characters: characters,
            slug: "test",
            level: 1,
            meanings: [MeaningSnapshot(meaning: "Test", primary: true, acceptedAnswer: true)],
            readings: [ReadingSnapshot(reading: "test", primary: true, acceptedAnswer: true)]
        )
    }
}

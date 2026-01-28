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
        let assignment = PersistentAssignment.mock(id: 1, subjectID: 100)
        let subject = PersistentSubject.mock(id: 100)
        
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
        let assignment = PersistentAssignment.mock(id: 1, subjectID: 100)
        let subject = PersistentSubject.mock(id: 100)
        
        assignmentRepo.mockAssignments = [assignment]
        subjectRepo.mockSubject = subject
        
        await sut.loadReviews()
        
        let firstItem = sut.currentItem
        XCTAssertNotNil(firstItem)
        
        await sut.submitAnswer("test")
        
        XCTAssertNotEqual(sut.currentItem?.id, firstItem?.id)
        XCTAssertNotNil(sut.currentItem)
        
        await sut.submitAnswer("test")
        XCTAssertNil(sut.currentItem)
        if case .complete = sut.state {
            // Success
        } else {
            XCTFail("Expected .complete state")
        }
    }
}

// MARK: - Mocks & Helpers

extension PersistentAssignment {
    static func mock(id: Int, subjectID: Int, subjectType: SubjectType = .kanji) -> PersistentAssignment {
        let data = AssignmentData(
            createdAt: Date(),
            subjectID: subjectID,
            subjectType: subjectType,
            srsStage: 1,
            availableAt: Date()
        )
        let assignment = Assignment(id: id, object: "assignment", url: "", dataUpdatedAt: nil, data: data)
        return PersistentAssignment(from: assignment)
    }
}

extension PersistentSubject {
    static func mock(id: Int, object: String = "kanji", characters: String = "漢") -> PersistentSubject {
        return PersistentSubject(
            id: id,
            object: object,
            url: "",
            dataUpdatedAt: nil,
            level: 1,
            slug: "test",
            documentURL: "",
            hiddenAt: nil,
            characters: characters,
            meanings: [PersistentMeaning(meaning: "Test", primary: true, acceptedAnswer: true)],
            readings: [PersistentReading(reading: "test", primary: true, acceptedAnswer: true)]
        )
    }
}

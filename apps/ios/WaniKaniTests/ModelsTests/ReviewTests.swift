import XCTest
@testable import WaniKaniCore

final class ReviewTests: XCTestCase {
    
    private var decoder: JSONDecoder!
    
    override func setUp() {
        super.setUp()
        decoder = .wanikaniDecoder()
    }
    
    func test_review_decodesFromJSON() throws {
        let json = """
        {
            "id": 67890,
            "object": "review",
            "url": "https://api.wanikani.com/v2/reviews/67890",
            "data_updated_at": "2023-10-27T15:45:00.000Z",
            "data": {
                "created_at": "2023-10-27T15:45:00.000Z",
                "assignment_id": 12345,
                "subject_id": 440,
                "spaced_repetition_system_id": 1,
                "starting_srs_stage": 4,
                "ending_srs_stage": 5,
                "incorrect_meaning_answers": 0,
                "incorrect_reading_answers": 1
            }
        }
        """.data(using: .utf8)!
        
        let review = try decoder.decode(Review.self, from: json)
        
        XCTAssertEqual(review.id, 67890)
        XCTAssertEqual(review.data.assignmentID, 12345)
        XCTAssertEqual(review.data.subjectID, 440)
        XCTAssertEqual(review.data.startingSRSStage, 4)
        XCTAssertEqual(review.data.endingSRSStage, 5)
        XCTAssertTrue(review.data.didLevelUp)
        XCTAssertFalse(review.data.didLevelDown)
    }
    
    func test_reviewData_isCorrect_whenNoIncorrectAnswers() {
        let data = ReviewData(
            createdAt: Date(),
            assignmentID: 1,
            subjectID: 1,
            spacedRepetitionSystemID: 1,
            startingSRSStage: 4,
            endingSRSStage: 5,
            incorrectMeaningAnswers: 0,
            incorrectReadingAnswers: 0
        )
        
        XCTAssertTrue(data.isCorrect)
        XCTAssertEqual(data.totalIncorrect, 0)
    }
    
    func test_reviewData_isNotCorrect_whenHasIncorrectAnswers() {
        let data = ReviewData(
            createdAt: Date(),
            assignmentID: 1,
            subjectID: 1,
            spacedRepetitionSystemID: 1,
            startingSRSStage: 4,
            endingSRSStage: 3,
            incorrectMeaningAnswers: 1,
            incorrectReadingAnswers: 2
        )
        
        XCTAssertFalse(data.isCorrect)
        XCTAssertEqual(data.totalIncorrect, 3)
        XCTAssertTrue(data.didLevelDown)
    }
}

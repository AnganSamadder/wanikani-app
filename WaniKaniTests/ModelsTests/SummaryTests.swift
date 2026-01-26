import XCTest
@testable import WaniKaniCore

final class SummaryTests: XCTestCase {
    
    private var decoder: JSONDecoder!
    
    override func setUp() {
        super.setUp()
        decoder = .wanikaniDecoder()
    }
    
    func test_summary_decodesFromJSON() throws {
        let json = """
        {
            "object": "report",
            "url": "https://api.wanikani.com/v2/summary",
            "data_updated_at": "2023-10-27T15:45:00.000Z",
            "data": {
                "lessons": [
                    {
                        "available_at": "2023-10-27T00:00:00.000Z",
                        "subject_ids": [1, 2, 3]
                    }
                ],
                "reviews": [
                    {
                        "available_at": "2023-10-27T00:00:00.000Z",
                        "subject_ids": [4, 5, 6, 7, 8]
                    },
                    {
                        "available_at": "2023-10-27T01:00:00.000Z",
                        "subject_ids": [9, 10]
                    }
                ],
                "next_reviews_at": "2023-10-27T01:00:00.000Z"
            }
        }
        """.data(using: .utf8)!
        
        let summary = try decoder.decode(Summary.self, from: json)
        
        XCTAssertEqual(summary.object, "report")
        XCTAssertEqual(summary.data.lessons.count, 1)
        XCTAssertEqual(summary.data.lessons.first?.subjectIDs, [1, 2, 3])
        XCTAssertEqual(summary.data.reviews.count, 2)
        XCTAssertNotNil(summary.data.nextReviewsAt)
    }
    
    func test_lessonSummary_decodesFromJSON() throws {
        let json = """
        {
            "available_at": "2023-10-27T15:00:00.000Z",
            "subject_ids": [100, 101, 102]
        }
        """.data(using: .utf8)!
        
        let lesson = try decoder.decode(LessonSummary.self, from: json)
        
        XCTAssertEqual(lesson.subjectIDs.count, 3)
        XCTAssertEqual(lesson.subjectIDs, [100, 101, 102])
    }
    
    func test_reviewSummary_decodesFromJSON() throws {
        let json = """
        {
            "available_at": "2023-10-27T16:00:00.000Z",
            "subject_ids": [200, 201]
        }
        """.data(using: .utf8)!
        
        let review = try decoder.decode(ReviewSummary.self, from: json)
        
        XCTAssertEqual(review.subjectIDs.count, 2)
        XCTAssertEqual(review.subjectIDs, [200, 201])
    }
}

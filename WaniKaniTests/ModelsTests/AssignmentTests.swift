import XCTest
@testable import WaniKaniCore

final class AssignmentTests: XCTestCase {
    
    private var decoder: JSONDecoder!
    
    override func setUp() {
        super.setUp()
        decoder = .wanikaniDecoder()
    }
    
    func test_assignment_decodesFromJSON() throws {
        let json = """
        {
            "id": 12345,
            "object": "assignment",
            "url": "https://api.wanikani.com/v2/assignments/12345",
            "data_updated_at": "2023-10-27T15:45:00.000Z",
            "data": {
                "created_at": "2023-01-01T00:00:00.000Z",
                "subject_id": 440,
                "subject_type": "kanji",
                "srs_stage": 5,
                "unlocked_at": "2023-01-01T00:00:00.000Z",
                "started_at": "2023-01-02T00:00:00.000Z",
                "passed_at": "2023-02-01T00:00:00.000Z",
                "burned_at": null,
                "available_at": "2023-10-01T00:00:00.000Z",
                "resurrected_at": null,
                "hidden": false
            }
        }
        """.data(using: .utf8)!
        
        let assignment = try decoder.decode(Assignment.self, from: json)
        
        XCTAssertEqual(assignment.id, 12345)
        XCTAssertEqual(assignment.data.subjectID, 440)
        XCTAssertEqual(assignment.data.subjectType, .kanji)
        XCTAssertEqual(assignment.data.srsStage, 5)
        XCTAssertEqual(assignment.data.srsStageName, "Guru")
        XCTAssertFalse(assignment.data.hidden)
    }
    
    func test_srsStageName_returnsCorrectNames() {
        let stageNames: [(Int, String)] = [
            (0, "Initiate"),
            (1, "Apprentice"),
            (2, "Apprentice"),
            (3, "Apprentice"),
            (4, "Apprentice"),
            (5, "Guru"),
            (6, "Guru"),
            (7, "Master"),
            (8, "Enlightened"),
            (9, "Burned"),
            (10, "Unknown")
        ]
        
        for (stage, expectedName) in stageNames {
            let data = AssignmentData(
                createdAt: Date(),
                subjectID: 1,
                subjectType: .kanji,
                srsStage: stage
            )
            XCTAssertEqual(data.srsStageName, expectedName)
        }
    }
    
    func test_isAvailableForReview_whenAvailableDateInPast_returnsTrue() {
        let pastDate = Date(timeIntervalSinceNow: -3600)
        let data = AssignmentData(
            createdAt: Date(),
            subjectID: 1,
            subjectType: .kanji,
            srsStage: 3,
            availableAt: pastDate
        )
        
        XCTAssertTrue(data.isAvailableForReview)
    }
    
    func test_isAvailableForReview_whenAvailableDateInFuture_returnsFalse() {
        let futureDate = Date(timeIntervalSinceNow: 3600)
        let data = AssignmentData(
            createdAt: Date(),
            subjectID: 1,
            subjectType: .kanji,
            srsStage: 3,
            availableAt: futureDate
        )
        
        XCTAssertFalse(data.isAvailableForReview)
    }
    
    func test_isAvailableForLesson_whenNotStarted_returnsTrue() {
        let data = AssignmentData(
            createdAt: Date(),
            subjectID: 1,
            subjectType: .radical,
            srsStage: 0,
            startedAt: nil
        )
        
        XCTAssertTrue(data.isAvailableForLesson)
    }
}

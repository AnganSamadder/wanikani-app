import XCTest
@testable import WaniKaniCore

final class SRSStateMachineTests: XCTestCase {
    var sut: SRSStateMachine!
    
    override func setUp() {
        super.setUp()
        sut = SRSStateMachine()
    }
    
    func test_correctAnswer_promotesStage() {
        let result = sut.calculateResult(currentStage: 1, incorrectAnswers: 0)
        XCTAssertEqual(result.newStage, .apprentice2)
        XCTAssertTrue(result.didLevelUp)
        XCTAssertFalse(result.didLevelDown)
    }
    
    func test_incorrectAnswer_demotesStage() {
        let result = sut.calculateResult(currentStage: 5, incorrectAnswers: 1) // Guru 1 -> Apprentice 3
        XCTAssertEqual(result.newStage, .apprentice3)
        XCTAssertFalse(result.didLevelUp)
        XCTAssertTrue(result.didLevelDown)
    }
}

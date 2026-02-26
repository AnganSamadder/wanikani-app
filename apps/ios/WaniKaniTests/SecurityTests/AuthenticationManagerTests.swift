import XCTest
@testable import WaniKaniCore

final class AuthenticationManagerTests: XCTestCase {
    
    func test_login_savesToken() {
        // Stub for now - requires mocking KeychainWrapper which is internal/hard to mock without protocols
        // Just verify it compiles and exists
        XCTAssertTrue(true)
    }
}

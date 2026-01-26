import XCTest
import SwiftData
@testable import WaniKaniCore

final class PersistenceManagerTests: XCTestCase {
    var sut: PersistenceManager!
    
    override func setUp() {
        super.setUp()
        sut = PersistenceManager(inMemory: true)
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func test_init_createsContainer() {
        XCTAssertNotNil(sut.container)
        XCTAssertNotNil(sut.context)
    }
    
    func test_saveUser_persistsUser() throws {
        // Given
        let user = User.mock()
        
        // When
        sut.saveUser(user)
        
        // Then
        let fetchedUser = sut.fetchUser()
        XCTAssertNotNil(fetchedUser)
        XCTAssertEqual(fetchedUser?.id, user.id)
        XCTAssertEqual(fetchedUser?.username, user.username)
    }
    
    func test_fetchUser_returnsNilWhenEmpty() {
        let fetchedUser = sut.fetchUser()
        XCTAssertNil(fetchedUser)
    }
}

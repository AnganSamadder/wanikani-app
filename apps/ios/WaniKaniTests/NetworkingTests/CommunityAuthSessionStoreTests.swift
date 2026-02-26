import XCTest
@testable import WaniKaniCore

final class CommunityAuthSessionStoreTests: XCTestCase {
    func test_currentAuthToken_whenStoreIsNew_returnsNil() async {
        let store = InMemoryCommunityAuthSessionStore()
        let token = await store.currentAuthToken()

        XCTAssertNil(token)
    }

    func test_setAuthToken_whenTokenIsProvided_returnsToken() async {
        let store = InMemoryCommunityAuthSessionStore()
        await store.setAuthToken("test-token")
        let token = await store.currentAuthToken()

        XCTAssertEqual(token, "test-token")
    }

    func test_setAuthToken_whenTokenIsCleared_returnsNil() async {
        let store = InMemoryCommunityAuthSessionStore(token: "initial")
        await store.setAuthToken(nil)
        let token = await store.currentAuthToken()

        XCTAssertNil(token)
    }
}

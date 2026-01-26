import XCTest
@testable import WaniKaniCore

final class PreferencesManagerTests: XCTestCase {
    
    var sut: PreferencesManager!
    var mockUserDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        mockUserDefaults = UserDefaults(suiteName: "TestDefaults")!
        sut = PreferencesManager(userDefaults: mockUserDefaults)
        mockUserDefaults.removePersistentDomain(forName: "TestDefaults")
    }
    
    override func tearDown() {
        mockUserDefaults.removePersistentDomain(forName: "TestDefaults")
        sut = nil
        mockUserDefaults = nil
        super.tearDown()
    }
    
    func test_darkModeEnabled_defaultValue() {
        XCTAssertFalse(sut.darkModeEnabled)
    }
    
    func test_darkModeEnabled_getSet() {
        sut.darkModeEnabled = true
        
        XCTAssertTrue(sut.darkModeEnabled)
    }
    
    func test_notificationsEnabled_defaultValue() {
        XCTAssertFalse(sut.notificationsEnabled)
    }
    
    func test_notificationsEnabled_getSet() {
        sut.notificationsEnabled = true
        
        XCTAssertTrue(sut.notificationsEnabled)
    }
    
    func test_lessonsBatchSize_defaultValue() {
        XCTAssertEqual(sut.lessonsBatchSize, 5)
    }
    
    func test_lessonsBatchSize_getSet() {
        sut.lessonsBatchSize = 10
        
        XCTAssertEqual(sut.lessonsBatchSize, 10)
    }
    
    func test_lessonsBatchSize_returnsDefaultWhenZero() {
        mockUserDefaults.set(0, forKey: "lessonsBatchSize")
        
        XCTAssertEqual(sut.lessonsBatchSize, 5)
    }
    
    func test_autoplayAudio_defaultValue() {
        XCTAssertFalse(sut.autoplayAudio)
    }
    
    func test_autoplayAudio_getSet() {
        sut.autoplayAudio = true
        
        XCTAssertTrue(sut.autoplayAudio)
    }
    
    func test_enabledScriptIDs_defaultValue() {
        XCTAssertEqual(sut.enabledScriptIDs, [])
    }
    
    func test_enabledScriptIDs_getSet() {
        let scriptIDs = [1, 2, 3, 5, 8]
        
        sut.enabledScriptIDs = scriptIDs
        
        XCTAssertEqual(sut.enabledScriptIDs, scriptIDs)
    }
    
    func test_lastSyncDate_defaultValue() {
        XCTAssertNil(sut.lastSyncDate)
    }
    
    func test_lastSyncDate_getSet() {
        let now = Date()
        
        sut.lastSyncDate = now
        
        XCTAssertEqual(sut.lastSyncDate?.timeIntervalSince1970, now.timeIntervalSince1970, accuracy: 0.01)
    }
    
    func test_selectedPrototypeMode_defaultValue() {
        XCTAssertEqual(sut.selectedPrototypeMode, "webview")
    }
    
    func test_selectedPrototypeMode_getSet() {
        sut.selectedPrototypeMode = "native"
        
        XCTAssertEqual(sut.selectedPrototypeMode, "native")
    }
    
    func test_reset_clearsAllPreferences() {
        sut.darkModeEnabled = true
        sut.notificationsEnabled = true
        sut.lessonsBatchSize = 10
        sut.autoplayAudio = true
        sut.enabledScriptIDs = [1, 2, 3]
        sut.lastSyncDate = Date()
        sut.selectedPrototypeMode = "native"
        
        sut.reset()
        
        XCTAssertFalse(sut.darkModeEnabled)
        XCTAssertFalse(sut.notificationsEnabled)
        XCTAssertEqual(sut.lessonsBatchSize, 5)
        XCTAssertFalse(sut.autoplayAudio)
        XCTAssertEqual(sut.enabledScriptIDs, [])
        XCTAssertNil(sut.lastSyncDate)
        XCTAssertEqual(sut.selectedPrototypeMode, "webview")
    }
}

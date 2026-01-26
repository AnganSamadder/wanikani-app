import XCTest
@testable import WaniKaniCore

final class KeychainWrapperTests: XCTestCase {
    var sut: KeychainWrapper!
    let testService = "com.wanikani.app.tests"
    let testKey = "test_api_key"
    
    override func setUp() {
        super.setUp()
        sut = KeychainWrapper(service: testService)
        
        // Clean up any existing test data
        try? sut.delete(forKey: testKey)
    }
    
    override func tearDown() {
        // Clean up test data
        try? sut.delete(forKey: testKey)
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Save Tests
    
    func test_save_data_success() throws {
        // Given
        let testData = "test_token_12345".data(using: .utf8)!
        
        // When
        try sut.save(testData, forKey: testKey)
        
        // Then
        let retrieved = try sut.retrieve(forKey: testKey)
        XCTAssertEqual(retrieved, testData)
    }
    
    func test_save_string_success() throws {
        // Given
        let testString = "test_api_token_abcdef"
        
        // When
        try sut.save(testString, forKey: testKey)
        
        // Then
        let retrieved = try sut.retrieveString(forKey: testKey)
        XCTAssertEqual(retrieved, testString)
    }
    
    func test_save_duplicate_updates_existing() throws {
        // Given
        let originalString = "original_token"
        let updatedString = "updated_token"
        
        // When - Save original
        try sut.save(originalString, forKey: testKey)
        
        // Then - Verify original
        var retrieved = try sut.retrieveString(forKey: testKey)
        XCTAssertEqual(retrieved, originalString)
        
        // When - Save again (should update)
        try sut.save(updatedString, forKey: testKey)
        
        // Then - Verify updated
        retrieved = try sut.retrieveString(forKey: testKey)
        XCTAssertEqual(retrieved, updatedString)
    }
    
    // MARK: - Retrieve Tests
    
    func test_retrieve_itemNotFound_throwsError() {
        // Given - No item saved
        
        // When/Then
        XCTAssertThrowsError(try sut.retrieve(forKey: "nonexistent_key")) { error in
            guard let keychainError = error as? KeychainError else {
                XCTFail("Expected KeychainError")
                return
            }
            
            if case .itemNotFound = keychainError {
                // Expected error
            } else {
                XCTFail("Expected itemNotFound error, got \(keychainError)")
            }
        }
    }
    
    func test_retrieveString_itemNotFound_throwsError() {
        // Given - No item saved
        
        // When/Then
        XCTAssertThrowsError(try sut.retrieveString(forKey: "nonexistent_key")) { error in
            guard let keychainError = error as? KeychainError else {
                XCTFail("Expected KeychainError")
                return
            }
            
            if case .itemNotFound = keychainError {
                // Expected error
            } else {
                XCTFail("Expected itemNotFound error, got \(keychainError)")
            }
        }
    }
    
    func test_retrieve_success() throws {
        // Given
        let testData = "sensitive_data".data(using: .utf8)!
        try sut.save(testData, forKey: testKey)
        
        // When
        let retrieved = try sut.retrieve(forKey: testKey)
        
        // Then
        XCTAssertEqual(retrieved, testData)
    }
    
    func test_retrieveString_success() throws {
        // Given
        let testString = "my_secret_api_key"
        try sut.save(testString, forKey: testKey)
        
        // When
        let retrieved = try sut.retrieveString(forKey: testKey)
        
        // Then
        XCTAssertEqual(retrieved, testString)
    }
    
    // MARK: - Delete Tests
    
    func test_delete_existingItem_success() throws {
        // Given
        let testString = "token_to_delete"
        try sut.save(testString, forKey: testKey)
        
        // Verify it exists
        _ = try sut.retrieveString(forKey: testKey)
        
        // When
        try sut.delete(forKey: testKey)
        
        // Then - Should throw itemNotFound
        XCTAssertThrowsError(try sut.retrieveString(forKey: testKey)) { error in
            guard let keychainError = error as? KeychainError else {
                XCTFail("Expected KeychainError")
                return
            }
            
            if case .itemNotFound = keychainError {
                // Expected error
            } else {
                XCTFail("Expected itemNotFound error after deletion")
            }
        }
    }
    
    func test_delete_nonexistentItem_doesNotThrow() {
        // Given - No item saved
        
        // When/Then - Should not throw
        XCTAssertNoThrow(try sut.delete(forKey: "nonexistent_key"))
    }
    
    // MARK: - Service Isolation Tests
    
    func test_differentServices_isolateData() throws {
        // Given
        let service1 = KeychainWrapper(service: "com.wanikani.service1")
        let service2 = KeychainWrapper(service: "com.wanikani.service2")
        let testString = "shared_key_data"
        let sharedKey = "shared_key"
        
        // Clean up
        try? service1.delete(forKey: sharedKey)
        try? service2.delete(forKey: sharedKey)
        
        // When
        try service1.save(testString, forKey: sharedKey)
        
        // Then - service2 should not see the data
        XCTAssertThrowsError(try service2.retrieveString(forKey: sharedKey)) { error in
            guard let keychainError = error as? KeychainError else {
                XCTFail("Expected KeychainError")
                return
            }
            
            if case .itemNotFound = keychainError {
                // Expected - services are isolated
            } else {
                XCTFail("Expected itemNotFound for different service")
            }
        }
        
        // Clean up
        try? service1.delete(forKey: sharedKey)
    }
    
    // MARK: - Edge Cases
    
    func test_save_emptyString_success() throws {
        // Given
        let emptyString = ""
        
        // When
        try sut.save(emptyString, forKey: testKey)
        
        // Then
        let retrieved = try sut.retrieveString(forKey: testKey)
        XCTAssertEqual(retrieved, emptyString)
    }
    
    func test_save_longString_success() throws {
        // Given
        let longString = String(repeating: "a", count: 10000)
        
        // When
        try sut.save(longString, forKey: testKey)
        
        // Then
        let retrieved = try sut.retrieveString(forKey: testKey)
        XCTAssertEqual(retrieved, longString)
    }
    
    func test_save_unicodeString_success() throws {
        // Given
        let unicodeString = "🔑🔒🌸日本語テスト"
        
        // When
        try sut.save(unicodeString, forKey: testKey)
        
        // Then
        let retrieved = try sut.retrieveString(forKey: testKey)
        XCTAssertEqual(retrieved, unicodeString)
    }
}

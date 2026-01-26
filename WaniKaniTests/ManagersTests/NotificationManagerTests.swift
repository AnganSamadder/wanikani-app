import XCTest
import UserNotifications
@testable import WaniKaniCore

final class NotificationManagerTests: XCTestCase {
    var sut: NotificationManager!
    var mockCenter: MockNotificationCenter!
    
    override func setUp() {
        super.setUp()
        mockCenter = MockNotificationCenter()
        sut = NotificationManager(center: mockCenter)
    }
    
    override func tearDown() {
        sut = nil
        mockCenter = nil
        super.tearDown()
    }
    
    func test_requestAuthorization_returnsAuthorizationResult() async throws {
        mockCenter.authorizationResult = true
        
        let result = try await sut.requestAuthorization()
        
        XCTAssertTrue(result)
        XCTAssertTrue(mockCenter.requestAuthorizationCalled)
    }
    
    func test_getAuthorizationStatus_returnsCorrectStatus() async {
        mockCenter.authorizationStatus = .authorized
        
        let status = await sut.getAuthorizationStatus()
        
        XCTAssertEqual(status, .authorized)
    }
    
    func test_scheduleReviewReminder_createsNotificationWithCorrectContent() async throws {
        let reviewDate = Date(timeIntervalSince1970: 1737835200)
        let reviewCount = 42
        
        try await sut.scheduleReviewReminder(at: reviewDate, reviewCount: reviewCount)
        
        XCTAssertEqual(mockCenter.addedRequests.count, 1)
        
        guard let request = mockCenter.addedRequests.first else {
            XCTFail("No notification request was added")
            return
        }
        
        XCTAssertEqual(request.content.title, "Reviews Available")
        XCTAssertEqual(request.content.body, "You have 42 reviews waiting!")
        XCTAssertEqual(request.content.badge, NSNumber(value: 42))
        XCTAssertNotNil(request.content.sound)
        XCTAssertTrue(request.identifier.hasPrefix("review-reminder-"))
    }
    
    func test_scheduleReviewReminder_singularMessage_whenOneReview() async throws {
        let reviewDate = Date()
        
        try await sut.scheduleReviewReminder(at: reviewDate, reviewCount: 1)
        
        guard let request = mockCenter.addedRequests.first else {
            XCTFail("No notification request was added")
            return
        }
        
        XCTAssertEqual(request.content.body, "You have 1 review waiting!")
    }
    
    func test_scheduleLessonReminder_createsNotificationWithCorrectContent() async throws {
        let lessonCount = 15
        
        try await sut.scheduleLessonReminder(lessonCount: lessonCount)
        
        XCTAssertEqual(mockCenter.addedRequests.count, 1)
        
        guard let request = mockCenter.addedRequests.first else {
            XCTFail("No notification request was added")
            return
        }
        
        XCTAssertEqual(request.content.title, "Lessons Available")
        XCTAssertEqual(request.content.body, "You have 15 lessons available!")
        XCTAssertNotNil(request.content.sound)
        XCTAssertEqual(request.identifier, "lesson-reminder")
    }
    
    func test_scheduleLessonReminder_singularMessage_whenOneLesson() async throws {
        try await sut.scheduleLessonReminder(lessonCount: 1)
        
        guard let request = mockCenter.addedRequests.first else {
            XCTFail("No notification request was added")
            return
        }
        
        XCTAssertEqual(request.content.body, "You have 1 lesson available!")
    }
    
    func test_cancelAllNotifications_removesAllPendingRequests() {
        sut.cancelAllNotifications()
        
        XCTAssertTrue(mockCenter.removeAllPendingRequestsCalled)
    }
    
    func test_cancelNotification_removesSpecificNotification() {
        let identifier = "test-notification-123"
        
        sut.cancelNotification(withIdentifier: identifier)
        
        XCTAssertTrue(mockCenter.removePendingRequestsCalled)
        XCTAssertEqual(mockCenter.removedIdentifiers, [identifier])
    }
    
    func test_getPendingNotifications_returnsNotifications() async {
        let mockRequest = UNNotificationRequest(
            identifier: "test-id",
            content: UNMutableNotificationContent(),
            trigger: nil
        )
        mockCenter.pendingRequests = [mockRequest]
        
        let pending = await sut.getPendingNotifications()
        
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.identifier, "test-id")
    }
}

final class MockNotificationCenter: NotificationCenterProtocol {
    var requestAuthorizationCalled = false
    var authorizationResult = true
    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var addedRequests: [UNNotificationRequest] = []
    var removeAllPendingRequestsCalled = false
    var removePendingRequestsCalled = false
    var removedIdentifiers: [String] = []
    var pendingRequests: [UNNotificationRequest] = []
    
    func requestAuthorization(options: UNAuthorizationOptions = []) async throws -> Bool {
        requestAuthorizationCalled = true
        return authorizationResult
    }
    
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        return authorizationStatus
    }
    
    func add(_ request: UNNotificationRequest) async throws {
        addedRequests.append(request)
    }
    
    func removeAllPendingNotificationRequests() {
        removeAllPendingRequestsCalled = true
        addedRequests.removeAll()
    }
    
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removePendingRequestsCalled = true
        removedIdentifiers = identifiers
        addedRequests.removeAll { identifiers.contains($0.identifier) }
    }
    
    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        return pendingRequests
    }
}

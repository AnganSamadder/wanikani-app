import Foundation
import UserNotifications

public final class NotificationManager {
    private let center: UNUserNotificationCenter
    
    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }
    
    // MARK: - Authorization
    
    public func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .badge, .sound])
    }
    
    public func getAuthorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }
    
    // MARK: - Scheduling
    
    public func scheduleReviewReminder(at date: Date, reviewCount: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Reviews Available"
        content.body = reviewCount == 1 
            ? "You have 1 review waiting!" 
            : "You have \(reviewCount) reviews waiting!"
        content.sound = .default
        content.badge = NSNumber(value: reviewCount)
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "review-reminder-\(date.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        try await center.add(request)
    }
    
    public func scheduleLessonReminder(lessonCount: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Lessons Available"
        content.body = lessonCount == 1 
            ? "You have 1 lesson available!" 
            : "You have \(lessonCount) lessons available!"
        content.sound = .default
        
        let tomorrowAt9AM = nextDayDateComponents(hour: 9, minute: 0)
        let trigger = UNCalendarNotificationTrigger(dateMatching: tomorrowAt9AM, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "lesson-reminder",
            content: content,
            trigger: trigger
        )
        
        try await center.add(request)
    }
    
    private func nextDayDateComponents(hour: Int, minute: Int) -> DateComponents {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1
        components.hour = hour
        components.minute = minute
        return components
    }
    
    // MARK: - Management
    
    public func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }
    
    public func cancelNotification(withIdentifier identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    public func getPendingNotifications() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }
    
    public func updateBadgeCount(_ count: Int) {
        let content = UNMutableNotificationContent()
        content.badge = NSNumber(value: count)
    }
}

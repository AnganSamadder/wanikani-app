import Foundation
@testable import WaniKaniCore

extension JSONDecoder {
    static func wanikaniDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format: \(dateString)"
            )
        }
        return decoder
    }
}

extension User {
    static func mock(
        id: String = "test-user-id",
        username: String = "testuser",
        level: Int = 10,
        subscriptionActive: Bool = true
    ) -> User {
        User(
            id: id,
            username: username,
            level: level,
            profileURL: "https://www.wanikani.com/users/testuser",
            startedAt: Date(),
            currentVacationStartedAt: nil,
            subscription: Subscription(
                active: subscriptionActive,
                type: .recurring,
                maxLevelGranted: 60,
                periodEndsAt: nil
            ),
            preferences: Preferences(
                defaultVoiceActorID: 1,
                lessonsAutoplayAudio: false,
                lessonsBatchSize: 5,
                lessonsPresentationOrder: "ascending_level_then_subject",
                reviewsAutoplayAudio: false,
                reviewsDisplaySRSIndicator: true
            )
        )
    }
}

import XCTest
@testable import WaniKaniCore

final class UserTests: XCTestCase {
    
    private var decoder: JSONDecoder!
    
    override func setUp() {
        super.setUp()
        decoder = .wanikaniDecoder()
    }
    
    func test_user_decodesFromJSON() throws {
        let json = """
        {
            "id": "5a6a5234-a392-4a87-8f3a-33f76c2c3e95",
            "username": "wanikani_user",
            "level": 25,
            "profile_url": "https://www.wanikani.com/users/wanikani_user",
            "started_at": "2020-01-01T00:00:00.000Z",
            "current_vacation_started_at": null,
            "subscription": {
                "active": true,
                "type": "lifetime",
                "max_level_granted": 60,
                "period_ends_at": null
            },
            "preferences": {
                "default_voice_actor_id": 1,
                "lessons_autoplay_audio": true,
                "lessons_batch_size": 5,
                "lessons_presentation_order": "ascending_level_then_subject",
                "reviews_autoplay_audio": false,
                "reviews_display_srs_indicator": true
            }
        }
        """.data(using: .utf8)!
        
        let user = try decoder.decode(User.self, from: json)
        
        XCTAssertEqual(user.id, "5a6a5234-a392-4a87-8f3a-33f76c2c3e95")
        XCTAssertEqual(user.username, "wanikani_user")
        XCTAssertEqual(user.level, 25)
        XCTAssertEqual(user.profileURL, "https://www.wanikani.com/users/wanikani_user")
        XCTAssertTrue(user.isLifetimeMember)
        XCTAssertFalse(user.isOnVacation)
    }
    
    func test_subscription_decodesAllTypes() throws {
        let types: [(String, SubscriptionType)] = [
            ("free", .free),
            ("recurring", .recurring),
            ("lifetime", .lifetime)
        ]
        
        for (jsonType, expectedType) in types {
            let json = """
            {
                "active": true,
                "type": "\(jsonType)",
                "max_level_granted": 60,
                "period_ends_at": null
            }
            """.data(using: .utf8)!
            
            let subscription = try decoder.decode(Subscription.self, from: json)
            XCTAssertEqual(subscription.type, expectedType)
        }
    }
    
    func test_user_onVacation_returnsTrue() throws {
        let json = """
        {
            "id": "test-id",
            "username": "test_user",
            "level": 1,
            "profile_url": "https://example.com",
            "started_at": "2020-01-01T00:00:00.000Z",
            "current_vacation_started_at": "2024-01-15T00:00:00.000Z",
            "subscription": {
                "active": true,
                "type": "free",
                "max_level_granted": 3,
                "period_ends_at": null
            },
            "preferences": {
                "default_voice_actor_id": 1,
                "lessons_autoplay_audio": true,
                "lessons_batch_size": 5,
                "lessons_presentation_order": "ascending_level_then_subject",
                "reviews_autoplay_audio": false,
                "reviews_display_srs_indicator": true
            }
        }
        """.data(using: .utf8)!
        
        let user = try decoder.decode(User.self, from: json)
        XCTAssertTrue(user.isOnVacation)
    }
}

import Foundation

// MARK: - User

public struct User: Codable, Equatable, Identifiable {
    public let id: String
    public let username: String
    public let level: Int
    public let profileURL: String
    public let startedAt: Date
    public let currentVacationStartedAt: Date?
    public let subscription: Subscription
    public let preferences: Preferences
    
    public var isLifetimeMember: Bool { subscription.type == .lifetime }
    public var isOnVacation: Bool { currentVacationStartedAt != nil }
    
    private enum CodingKeys: String, CodingKey {
        case id, username, level
        case profileURL = "profile_url"
        case startedAt = "started_at"
        case currentVacationStartedAt = "current_vacation_started_at"
        case subscription, preferences
    }
    
    public init(
        id: String,
        username: String,
        level: Int,
        profileURL: String,
        startedAt: Date,
        currentVacationStartedAt: Date? = nil,
        subscription: Subscription,
        preferences: Preferences
    ) {
        self.id = id
        self.username = username
        self.level = level
        self.profileURL = profileURL
        self.startedAt = startedAt
        self.currentVacationStartedAt = currentVacationStartedAt
        self.subscription = subscription
        self.preferences = preferences
    }
}

// MARK: - Subscription

public struct Subscription: Codable, Equatable {
    public let active: Bool
    public let type: SubscriptionType
    public let maxLevelGranted: Int
    public let periodEndsAt: Date?
    
    private enum CodingKeys: String, CodingKey {
        case active, type
        case maxLevelGranted = "max_level_granted"
        case periodEndsAt = "period_ends_at"
    }
    
    public init(active: Bool, type: SubscriptionType, maxLevelGranted: Int, periodEndsAt: Date? = nil) {
        self.active = active
        self.type = type
        self.maxLevelGranted = maxLevelGranted
        self.periodEndsAt = periodEndsAt
    }
}

public enum SubscriptionType: String, Codable {
    case free
    case recurring
    case lifetime
}

// MARK: - Preferences

public struct Preferences: Codable, Equatable {
    public let defaultVoiceActorID: Int
    public let lessonsAutoplayAudio: Bool
    public let lessonsBatchSize: Int
    public let lessonsPresentationOrder: String
    public let reviewsAutoplayAudio: Bool
    public let reviewsDisplaySRSIndicator: Bool
    
    private enum CodingKeys: String, CodingKey {
        case defaultVoiceActorID = "default_voice_actor_id"
        case lessonsAutoplayAudio = "lessons_autoplay_audio"
        case lessonsBatchSize = "lessons_batch_size"
        case lessonsPresentationOrder = "lessons_presentation_order"
        case reviewsAutoplayAudio = "reviews_autoplay_audio"
        case reviewsDisplaySRSIndicator = "reviews_display_srs_indicator"
    }
    
    public init(
        defaultVoiceActorID: Int,
        lessonsAutoplayAudio: Bool,
        lessonsBatchSize: Int,
        lessonsPresentationOrder: String,
        reviewsAutoplayAudio: Bool,
        reviewsDisplaySRSIndicator: Bool
    ) {
        self.defaultVoiceActorID = defaultVoiceActorID
        self.lessonsAutoplayAudio = lessonsAutoplayAudio
        self.lessonsBatchSize = lessonsBatchSize
        self.lessonsPresentationOrder = lessonsPresentationOrder
        self.reviewsAutoplayAudio = reviewsAutoplayAudio
        self.reviewsDisplaySRSIndicator = reviewsDisplaySRSIndicator
    }
}

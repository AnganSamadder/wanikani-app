import SwiftData
import Foundation

// MARK: - Models

// User models
@Model
public final class PersistentUser {
    @Attribute(.unique) public var id: String
    public var username: String
    public var level: Int
    public var profileURL: String
    public var startedAt: Date
    public var currentVacationStartedAt: Date?
    public var subscriptionActive: Bool
    public var subscriptionType: String
    public var maxLevelGranted: Int
    public var periodEndsAt: Date?
    
    // Preferences
    public var defaultVoiceActorID: Int
    public var lessonsAutoplayAudio: Bool
    public var lessonsBatchSize: Int
    public var lessonsPresentationOrder: String
    public var reviewsAutoplayAudio: Bool
    public var reviewsDisplaySRSIndicator: Bool
    public var extraStudyAutoplayAudio: Bool
    public var reviewsPresentationOrder: String
    
    public init(from domainUser: User) {
        self.id = domainUser.id
        self.username = domainUser.username
        self.level = domainUser.level
        self.profileURL = domainUser.profileURL
        self.startedAt = domainUser.startedAt
        self.currentVacationStartedAt = domainUser.currentVacationStartedAt
        self.subscriptionActive = domainUser.subscription.active
        self.subscriptionType = domainUser.subscription.type.rawValue
        self.maxLevelGranted = domainUser.subscription.maxLevelGranted
        self.periodEndsAt = domainUser.subscription.periodEndsAt
        
        // Preferences
        self.defaultVoiceActorID = domainUser.preferences.defaultVoiceActorID
        self.lessonsAutoplayAudio = domainUser.preferences.lessonsAutoplayAudio
        self.lessonsBatchSize = domainUser.preferences.lessonsBatchSize
        self.lessonsPresentationOrder = domainUser.preferences.lessonsPresentationOrder
        self.reviewsAutoplayAudio = domainUser.preferences.reviewsAutoplayAudio
        self.reviewsDisplaySRSIndicator = domainUser.preferences.reviewsDisplaySRSIndicator
        self.extraStudyAutoplayAudio = domainUser.preferences.extraStudyAutoplayAudio
        self.reviewsPresentationOrder = domainUser.preferences.reviewsPresentationOrder
    }
    
    public func toDomain() -> User {
        User(
            id: id,
            username: username,
            level: level,
            profileURL: profileURL,
            startedAt: startedAt,
            currentVacationStartedAt: currentVacationStartedAt,
            subscription: Subscription(
                active: subscriptionActive,
                type: SubscriptionType(rawValue: subscriptionType) ?? .free,
                maxLevelGranted: maxLevelGranted,
                periodEndsAt: periodEndsAt
            ),
            preferences: Preferences(
                defaultVoiceActorID: defaultVoiceActorID,
                lessonsAutoplayAudio: lessonsAutoplayAudio,
                lessonsBatchSize: lessonsBatchSize,
                lessonsPresentationOrder: lessonsPresentationOrder,
                reviewsAutoplayAudio: reviewsAutoplayAudio,
                reviewsDisplaySRSIndicator: reviewsDisplaySRSIndicator,
                extraStudyAutoplayAudio: extraStudyAutoplayAudio,
                reviewsPresentationOrder: reviewsPresentationOrder
            )
        )
    }
}

// MARK: - Subject
@Model
public final class PersistentSubject {
    @Attribute(.unique) public var id: Int
    public var object: String
    public var url: String
    public var dataUpdatedAt: Date?
    public var level: Int
    public var slug: String
    public var documentURL: String
    public var hiddenAt: Date?
    public var characters: String?
    @Relationship(deleteRule: .cascade) public var meanings: [PersistentMeaning]
    
    public init(id: Int, object: String, url: String, dataUpdatedAt: Date?, level: Int, slug: String, documentURL: String, hiddenAt: Date?, characters: String?, meanings: [PersistentMeaning]) {
        self.id = id
        self.object = object
        self.url = url
        self.dataUpdatedAt = dataUpdatedAt
        self.level = level
        self.slug = slug
        self.documentURL = documentURL
        self.hiddenAt = hiddenAt
        self.characters = characters
        self.meanings = meanings
    }
}

@Model
public final class PersistentMeaning {
    public var meaning: String
    public var primary: Bool
    public var acceptedAnswer: Bool
    
    public init(meaning: String, primary: Bool, acceptedAnswer: Bool) {
        self.meaning = meaning
        self.primary = primary
        self.acceptedAnswer = acceptedAnswer
    }
}

// MARK: - Assignment
@Model
public final class PersistentAssignment {
    @Attribute(.unique) public var id: Int
    public var subjectID: Int
    public var subjectType: String
    public var srsStage: Int
    public var availableAt: Date?
    public var startedAt: Date?
    public var passedAt: Date?
    public var burnedAt: Date?
    public var hidden: Bool
    
    public init(from assignment: Assignment) {
        self.id = assignment.id
        self.subjectID = assignment.data.subjectID
        self.subjectType = assignment.data.subjectType.rawValue
        self.srsStage = assignment.data.srsStage
        self.availableAt = assignment.data.availableAt
        self.startedAt = assignment.data.startedAt
        self.passedAt = assignment.data.passedAt
        self.burnedAt = assignment.data.burnedAt
        self.hidden = assignment.data.hidden
    }
}

// MARK: - Review
@Model
public final class PersistentReview {
    @Attribute(.unique) public var id: Int
    public var assignmentID: Int
    public var subjectID: Int
    public var startingSRSStage: Int
    public var endingSRSStage: Int
    
    public init(from review: Review) {
        self.id = review.id
        self.assignmentID = review.data.assignmentID
        self.subjectID = review.data.subjectID
        self.startingSRSStage = review.data.startingSRSStage
        self.endingSRSStage = review.data.endingSRSStage
    }
}

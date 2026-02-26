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
    public var readings: [PersistentReading]
    public var meaningMnemonic: String?
    public var meaningHint: String?
    public var readingMnemonic: String?
    public var readingHint: String?
    public var auxiliaryMeaningsJSON: Data?
    public var contextSentencesJSON: Data?
    public var pronunciationAudiosJSON: Data?
    public var componentSubjectIDsJSON: Data?
    public var amalgamationSubjectIDsJSON: Data?
    public var visuallySimilarSubjectIDsJSON: Data?
    public var partsOfSpeechJSON: Data?

    public init(id: Int, object: String, url: String, dataUpdatedAt: Date?, level: Int, slug: String, documentURL: String, hiddenAt: Date?, characters: String?, meanings: [PersistentMeaning], readings: [PersistentReading], meaningMnemonic: String? = nil, meaningHint: String? = nil, readingMnemonic: String? = nil, readingHint: String? = nil, auxiliaryMeaningsJSON: Data? = nil, contextSentencesJSON: Data? = nil, pronunciationAudiosJSON: Data? = nil, componentSubjectIDsJSON: Data? = nil, amalgamationSubjectIDsJSON: Data? = nil, visuallySimilarSubjectIDsJSON: Data? = nil, partsOfSpeechJSON: Data? = nil) {
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
        self.readings = readings
        self.meaningMnemonic = meaningMnemonic
        self.meaningHint = meaningHint
        self.readingMnemonic = readingMnemonic
        self.readingHint = readingHint
        self.auxiliaryMeaningsJSON = auxiliaryMeaningsJSON
        self.contextSentencesJSON = contextSentencesJSON
        self.pronunciationAudiosJSON = pronunciationAudiosJSON
        self.componentSubjectIDsJSON = componentSubjectIDsJSON
        self.amalgamationSubjectIDsJSON = amalgamationSubjectIDsJSON
        self.visuallySimilarSubjectIDsJSON = visuallySimilarSubjectIDsJSON
        self.partsOfSpeechJSON = partsOfSpeechJSON
    }

    public init(from subjectData: SubjectData) {
        self.id = subjectData.id
        self.object = subjectData.object
        self.url = subjectData.url
        self.dataUpdatedAt = subjectData.dataUpdatedAt

        let encoder = JSONEncoder()

        switch subjectData.data {
        case .radical(let data):
            self.level = data.level
            self.slug = data.slug
            self.documentURL = data.documentURL
            self.hiddenAt = data.hiddenAt
            self.characters = data.characters
            self.meanings = data.meanings.map { PersistentMeaning(meaning: $0.meaning, primary: $0.primary, acceptedAnswer: $0.acceptedAnswer) }
            self.readings = []
            self.meaningMnemonic = data.meaningMnemonic
            self.meaningHint = nil
            self.readingMnemonic = nil
            self.readingHint = nil
            self.auxiliaryMeaningsJSON = try? encoder.encode(data.auxiliaryMeanings)
            self.contextSentencesJSON = nil
            self.pronunciationAudiosJSON = nil
            self.componentSubjectIDsJSON = nil
            self.amalgamationSubjectIDsJSON = try? encoder.encode(data.amalgamationSubjectIDs)
            self.visuallySimilarSubjectIDsJSON = nil
            self.partsOfSpeechJSON = nil
        case .kanji(let data):
            self.level = data.level
            self.slug = data.slug
            self.documentURL = data.documentURL
            self.hiddenAt = data.hiddenAt
            self.characters = data.characters
            self.meanings = data.meanings.map { PersistentMeaning(meaning: $0.meaning, primary: $0.primary, acceptedAnswer: $0.acceptedAnswer) }
            self.readings = data.readings.map { PersistentReading(reading: $0.reading, primary: $0.primary, acceptedAnswer: $0.acceptedAnswer, type: $0.type) }
            self.meaningMnemonic = data.meaningMnemonic
            self.meaningHint = data.meaningHint
            self.readingMnemonic = data.readingMnemonic
            self.readingHint = data.readingHint
            self.auxiliaryMeaningsJSON = try? encoder.encode(data.auxiliaryMeanings)
            self.contextSentencesJSON = nil
            self.pronunciationAudiosJSON = nil
            self.componentSubjectIDsJSON = try? encoder.encode(data.componentSubjectIDs)
            self.amalgamationSubjectIDsJSON = try? encoder.encode(data.amalgamationSubjectIDs)
            self.visuallySimilarSubjectIDsJSON = try? encoder.encode(data.visuallySimilarSubjectIDs)
            self.partsOfSpeechJSON = nil
        case .vocabulary(let data):
            self.level = data.level
            self.slug = data.slug
            self.documentURL = data.documentURL
            self.hiddenAt = data.hiddenAt
            self.characters = data.characters
            self.meanings = data.meanings.map { PersistentMeaning(meaning: $0.meaning, primary: $0.primary, acceptedAnswer: $0.acceptedAnswer) }
            self.readings = data.readings.map { PersistentReading(reading: $0.reading, primary: $0.primary, acceptedAnswer: $0.acceptedAnswer, type: $0.type) }
            self.meaningMnemonic = data.meaningMnemonic
            self.meaningHint = nil
            self.readingMnemonic = data.readingMnemonic
            self.readingHint = nil
            self.auxiliaryMeaningsJSON = try? encoder.encode(data.auxiliaryMeanings)
            self.contextSentencesJSON = try? encoder.encode(data.contextSentences)
            self.pronunciationAudiosJSON = try? encoder.encode(data.pronunciationAudios)
            self.componentSubjectIDsJSON = try? encoder.encode(data.componentSubjectIDs)
            self.amalgamationSubjectIDsJSON = nil
            self.visuallySimilarSubjectIDsJSON = nil
            self.partsOfSpeechJSON = try? encoder.encode(data.partsOfSpeech)
        }
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

public struct PersistentReading: Codable, Hashable, Sendable {
    public var reading: String
    public var primary: Bool
    public var acceptedAnswer: Bool
    public var type: String?
    
    public init(reading: String, primary: Bool, acceptedAnswer: Bool, type: String? = nil) {
        self.reading = reading
        self.primary = primary
        self.acceptedAnswer = acceptedAnswer
        self.type = type
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
    public var unlockedAt: Date?
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
        self.unlockedAt = assignment.data.unlockedAt
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
    public var createdAt: Date?
    public var incorrectMeaningAnswers: Int = 0
    public var incorrectReadingAnswers: Int = 0

    public init(from review: Review) {
        self.id = review.id
        self.assignmentID = review.data.assignmentID
        self.subjectID = review.data.subjectID
        self.startingSRSStage = review.data.startingSRSStage
        self.endingSRSStage = review.data.endingSRSStage
        self.createdAt = review.data.createdAt
        self.incorrectMeaningAnswers = review.data.incorrectMeaningAnswers
        self.incorrectReadingAnswers = review.data.incorrectReadingAnswers
    }
}

// MARK: - Pending Review

@Model
public final class PersistentPendingReview {
    @Attribute(.unique) public var assignmentID: Int
    public var subjectID: Int
    public var subjectType: String
    public var hasReadings: Bool
    public var meaningCompleted: Bool
    public var readingCompleted: Bool
    public var incorrectMeaningAnswers: Int
    public var incorrectReadingAnswers: Int
    public var updatedAt: Date

    public init(
        assignmentID: Int,
        subjectID: Int,
        subjectType: String,
        hasReadings: Bool,
        meaningCompleted: Bool,
        readingCompleted: Bool,
        incorrectMeaningAnswers: Int,
        incorrectReadingAnswers: Int,
        updatedAt: Date = Date()
    ) {
        self.assignmentID = assignmentID
        self.subjectID = subjectID
        self.subjectType = subjectType
        self.hasReadings = hasReadings
        self.meaningCompleted = meaningCompleted
        self.readingCompleted = readingCompleted
        self.incorrectMeaningAnswers = incorrectMeaningAnswers
        self.incorrectReadingAnswers = incorrectReadingAnswers
        self.updatedAt = updatedAt
    }
}

// MARK: - Study Material

@Model
public final class PersistentStudyMaterial {
    @Attribute(.unique) public var subjectID: Int
    public var meaningNote: String?
    public var readingNote: String?
    public var meaningSynonyms: [String]
    public var updatedAt: Date

    public init(
        subjectID: Int,
        meaningNote: String?,
        readingNote: String?,
        meaningSynonyms: [String],
        updatedAt: Date = Date()
    ) {
        self.subjectID = subjectID
        self.meaningNote = meaningNote
        self.readingNote = readingNote
        self.meaningSynonyms = meaningSynonyms
        self.updatedAt = updatedAt
    }

    public convenience init(from studyMaterial: StudyMaterial) {
        self.init(
            subjectID: studyMaterial.data.subjectID,
            meaningNote: studyMaterial.data.meaningNote,
            readingNote: studyMaterial.data.readingNote,
            meaningSynonyms: studyMaterial.data.meaningSynonyms,
            updatedAt: studyMaterial.dataUpdatedAt ?? Date()
        )
    }
}

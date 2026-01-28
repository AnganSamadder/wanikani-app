import Foundation

// MARK: - Sendable Snapshots for Cross-Actor Communication

/// Sendable snapshot of a Subject for use in repositories and ViewModels
public struct SubjectSnapshot: Sendable, Identifiable, Hashable {
    public let id: Int
    public let object: String
    public let characters: String?
    public let slug: String
    public let level: Int
    public let meanings: [MeaningSnapshot]
    public let readings: [ReadingSnapshot]
    
    public init(
        id: Int,
        object: String,
        characters: String?,
        slug: String,
        level: Int,
        meanings: [MeaningSnapshot],
        readings: [ReadingSnapshot]
    ) {
        self.id = id
        self.object = object
        self.characters = characters
        self.slug = slug
        self.level = level
        self.meanings = meanings
        self.readings = readings
    }
    
    /// Returns accepted meanings (used for answer checking)
    public var acceptedMeanings: [String] {
        meanings.filter { $0.acceptedAnswer }.map { $0.meaning }
    }
    
    /// Returns accepted readings (used for answer checking)
    public var acceptedReadings: [String] {
        readings.filter { $0.acceptedAnswer }.map { $0.reading }
    }
    
    /// Returns primary meaning
    public var primaryMeaning: String? {
        meanings.first(where: { $0.primary })?.meaning
    }
    
    /// Returns primary reading
    public var primaryReading: String? {
        readings.first(where: { $0.primary })?.reading
    }
    
    /// Whether this subject has readings (kanji/vocabulary)
    public var hasReadings: Bool {
        !readings.isEmpty
    }
}

/// Sendable snapshot of a Meaning
public struct MeaningSnapshot: Sendable, Hashable {
    public let meaning: String
    public let primary: Bool
    public let acceptedAnswer: Bool
    
    public init(meaning: String, primary: Bool, acceptedAnswer: Bool) {
        self.meaning = meaning
        self.primary = primary
        self.acceptedAnswer = acceptedAnswer
    }
}

/// Sendable snapshot of a Reading
public struct ReadingSnapshot: Sendable, Hashable {
    public let reading: String
    public let primary: Bool
    public let acceptedAnswer: Bool
    public let type: String?
    
    public init(reading: String, primary: Bool, acceptedAnswer: Bool, type: String? = nil) {
        self.reading = reading
        self.primary = primary
        self.acceptedAnswer = acceptedAnswer
        self.type = type
    }
}

/// Sendable snapshot of an Assignment for use in repositories and ViewModels
public struct AssignmentSnapshot: Sendable, Identifiable, Hashable {
    public let id: Int
    public let subjectID: Int
    public let subjectType: SubjectType
    public let srsStage: Int
    public let availableAt: Date?
    public let unlockedAt: Date?
    public let startedAt: Date?
    public let passedAt: Date?
    public let burnedAt: Date?
    public let hidden: Bool
    
    public init(
        id: Int,
        subjectID: Int,
        subjectType: SubjectType,
        srsStage: Int,
        availableAt: Date?,
        unlockedAt: Date?,
        startedAt: Date?,
        passedAt: Date?,
        burnedAt: Date?,
        hidden: Bool
    ) {
        self.id = id
        self.subjectID = subjectID
        self.subjectType = subjectType
        self.srsStage = srsStage
        self.availableAt = availableAt
        self.unlockedAt = unlockedAt
        self.startedAt = startedAt
        self.passedAt = passedAt
        self.burnedAt = burnedAt
        self.hidden = hidden
    }
    
    public var isAvailableForReview: Bool {
        guard let availableAt = availableAt else { return false }
        return availableAt <= Date()
    }
    
    public var isAvailableForLesson: Bool {
        srsStage == 0 && startedAt == nil && unlockedAt != nil
    }
    
    public var srsStageName: String {
        switch srsStage {
        case 0: return "Initiate"
        case 1...4: return "Apprentice"
        case 5, 6: return "Guru"
        case 7: return "Master"
        case 8: return "Enlightened"
        case 9: return "Burned"
        default: return "Unknown"
        }
    }
}

// MARK: - Conversion Extensions

extension SubjectSnapshot {
    init(from persistent: PersistentSubject) {
        self.id = persistent.id
        self.object = persistent.object
        self.characters = persistent.characters
        self.slug = persistent.slug
        self.level = persistent.level
        self.meanings = persistent.meanings.map { MeaningSnapshot(from: $0) }
        self.readings = persistent.readings.map { ReadingSnapshot(from: $0) }
    }
}

extension MeaningSnapshot {
    init(from persistent: PersistentMeaning) {
        self.meaning = persistent.meaning
        self.primary = persistent.primary
        self.acceptedAnswer = persistent.acceptedAnswer
    }
}

extension ReadingSnapshot {
    init(from persistent: PersistentReading) {
        self.reading = persistent.reading
        self.primary = persistent.primary
        self.acceptedAnswer = persistent.acceptedAnswer
        self.type = persistent.type
    }
}

extension AssignmentSnapshot {
    init(from persistent: PersistentAssignment) {
        self.id = persistent.id
        self.subjectID = persistent.subjectID
        self.subjectType = SubjectType(rawValue: persistent.subjectType) ?? .radical
        self.srsStage = persistent.srsStage
        self.availableAt = persistent.availableAt
        self.unlockedAt = persistent.unlockedAt
        self.startedAt = persistent.startedAt
        self.passedAt = persistent.passedAt
        self.burnedAt = persistent.burnedAt
        self.hidden = persistent.hidden
    }
}

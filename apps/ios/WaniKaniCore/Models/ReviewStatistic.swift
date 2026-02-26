import Foundation

// MARK: - Review Statistic

public struct ReviewStatistic: Codable, Equatable, Identifiable {
    public let id: Int
    public let object: String
    public let url: String
    public let dataUpdatedAt: Date?
    public let data: ReviewStatisticData
    
    private enum CodingKeys: String, CodingKey {
        case id, object, url
        case dataUpdatedAt = "data_updated_at"
        case data
    }
    
    public init(id: Int, object: String, url: String, dataUpdatedAt: Date?, data: ReviewStatisticData) {
        self.id = id
        self.object = object
        self.url = url
        self.dataUpdatedAt = dataUpdatedAt
        self.data = data
    }
}

public struct ReviewStatisticData: Codable, Equatable {
    public let createdAt: Date
    public let subjectID: Int
    public let subjectType: SubjectType
    public let meaningCorrect: Int
    public let meaningIncorrect: Int
    public let meaningMaxStreak: Int
    public let meaningCurrentStreak: Int
    public let readingCorrect: Int
    public let readingIncorrect: Int
    public let readingMaxStreak: Int
    public let readingCurrentStreak: Int
    public let percentageCorrect: Int
    public let hidden: Bool
    
    public var totalAnswers: Int {
        meaningCorrect + meaningIncorrect + readingCorrect + readingIncorrect
    }
    
    public var totalCorrect: Int {
        meaningCorrect + readingCorrect
    }
    
    private enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case subjectID = "subject_id"
        case subjectType = "subject_type"
        case meaningCorrect = "meaning_correct"
        case meaningIncorrect = "meaning_incorrect"
        case meaningMaxStreak = "meaning_max_streak"
        case meaningCurrentStreak = "meaning_current_streak"
        case readingCorrect = "reading_correct"
        case readingIncorrect = "reading_incorrect"
        case readingMaxStreak = "reading_max_streak"
        case readingCurrentStreak = "reading_current_streak"
        case percentageCorrect = "percentage_correct"
        case hidden
    }
    
    public init(
        createdAt: Date,
        subjectID: Int,
        subjectType: SubjectType,
        meaningCorrect: Int,
        meaningIncorrect: Int,
        meaningMaxStreak: Int,
        meaningCurrentStreak: Int,
        readingCorrect: Int,
        readingIncorrect: Int,
        readingMaxStreak: Int,
        readingCurrentStreak: Int,
        percentageCorrect: Int,
        hidden: Bool
    ) {
        self.createdAt = createdAt
        self.subjectID = subjectID
        self.subjectType = subjectType
        self.meaningCorrect = meaningCorrect
        self.meaningIncorrect = meaningIncorrect
        self.meaningMaxStreak = meaningMaxStreak
        self.meaningCurrentStreak = meaningCurrentStreak
        self.readingCorrect = readingCorrect
        self.readingIncorrect = readingIncorrect
        self.readingMaxStreak = readingMaxStreak
        self.readingCurrentStreak = readingCurrentStreak
        self.percentageCorrect = percentageCorrect
        self.hidden = hidden
    }
}

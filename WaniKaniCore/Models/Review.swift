import Foundation

// MARK: - Review

public struct Review: Codable, Equatable, Identifiable {
    public let id: Int
    public let object: String
    public let url: String
    public let dataUpdatedAt: Date?
    public let data: ReviewData
    
    private enum CodingKeys: String, CodingKey {
        case id, object, url
        case dataUpdatedAt = "data_updated_at"
        case data
    }
    
    public init(id: Int, object: String, url: String, dataUpdatedAt: Date?, data: ReviewData) {
        self.id = id
        self.object = object
        self.url = url
        self.dataUpdatedAt = dataUpdatedAt
        self.data = data
    }
}

public struct ReviewData: Codable, Equatable {
    public let createdAt: Date
    public let assignmentID: Int
    public let subjectID: Int
    public let spacedRepetitionSystemID: Int
    public let startingSRSStage: Int
    public let endingSRSStage: Int
    public let incorrectMeaningAnswers: Int
    public let incorrectReadingAnswers: Int
    
    public var isCorrect: Bool {
        incorrectMeaningAnswers == 0 && incorrectReadingAnswers == 0
    }
    
    public var totalIncorrect: Int {
        incorrectMeaningAnswers + incorrectReadingAnswers
    }
    
    public var didLevelUp: Bool {
        endingSRSStage > startingSRSStage
    }
    
    public var didLevelDown: Bool {
        endingSRSStage < startingSRSStage
    }
    
    private enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case assignmentID = "assignment_id"
        case subjectID = "subject_id"
        case spacedRepetitionSystemID = "spaced_repetition_system_id"
        case startingSRSStage = "starting_srs_stage"
        case endingSRSStage = "ending_srs_stage"
        case incorrectMeaningAnswers = "incorrect_meaning_answers"
        case incorrectReadingAnswers = "incorrect_reading_answers"
    }
    
    public init(
        createdAt: Date,
        assignmentID: Int,
        subjectID: Int,
        spacedRepetitionSystemID: Int,
        startingSRSStage: Int,
        endingSRSStage: Int,
        incorrectMeaningAnswers: Int,
        incorrectReadingAnswers: Int
    ) {
        self.createdAt = createdAt
        self.assignmentID = assignmentID
        self.subjectID = subjectID
        self.spacedRepetitionSystemID = spacedRepetitionSystemID
        self.startingSRSStage = startingSRSStage
        self.endingSRSStage = endingSRSStage
        self.incorrectMeaningAnswers = incorrectMeaningAnswers
        self.incorrectReadingAnswers = incorrectReadingAnswers
    }
}

import Foundation

// MARK: - Assignment

public struct Assignment: Codable, Equatable, Identifiable {
    public let id: Int
    public let object: String
    public let url: String
    public let dataUpdatedAt: Date?
    public let data: AssignmentData
    
    private enum CodingKeys: String, CodingKey {
        case id, object, url
        case dataUpdatedAt = "data_updated_at"
        case data
    }
    
    public init(id: Int, object: String, url: String, dataUpdatedAt: Date?, data: AssignmentData) {
        self.id = id
        self.object = object
        self.url = url
        self.dataUpdatedAt = dataUpdatedAt
        self.data = data
    }
}

public struct AssignmentData: Codable, Equatable {
    public let createdAt: Date
    public let subjectID: Int
    public let subjectType: SubjectType
    public let srsStage: Int
    public let unlockedAt: Date?
    public let startedAt: Date?
    public let passedAt: Date?
    public let burnedAt: Date?
    public let availableAt: Date?
    public let resurrectedAt: Date?
    public let hidden: Bool
    
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
    
    public var isAvailableForReview: Bool {
        guard let availableAt = availableAt else { return false }
        return availableAt <= Date()
    }
    
    public var isAvailableForLesson: Bool {
        srsStage == 0 && startedAt == nil
    }
    
    private enum CodingKeys: String, CodingKey {
        case hidden
        case createdAt = "created_at"
        case subjectID = "subject_id"
        case subjectType = "subject_type"
        case srsStage = "srs_stage"
        case unlockedAt = "unlocked_at"
        case startedAt = "started_at"
        case passedAt = "passed_at"
        case burnedAt = "burned_at"
        case availableAt = "available_at"
        case resurrectedAt = "resurrected_at"
    }
    
    public init(
        createdAt: Date,
        subjectID: Int,
        subjectType: SubjectType,
        srsStage: Int,
        unlockedAt: Date? = nil,
        startedAt: Date? = nil,
        passedAt: Date? = nil,
        burnedAt: Date? = nil,
        availableAt: Date? = nil,
        resurrectedAt: Date? = nil,
        hidden: Bool = false
    ) {
        self.createdAt = createdAt
        self.subjectID = subjectID
        self.subjectType = subjectType
        self.srsStage = srsStage
        self.unlockedAt = unlockedAt
        self.startedAt = startedAt
        self.passedAt = passedAt
        self.burnedAt = burnedAt
        self.availableAt = availableAt
        self.resurrectedAt = resurrectedAt
        self.hidden = hidden
    }
}

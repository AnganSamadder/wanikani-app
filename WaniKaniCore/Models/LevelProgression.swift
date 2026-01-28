import Foundation

// MARK: - Level Progression

public struct LevelProgression: Codable, Equatable, Identifiable {
    public let id: Int
    public let object: String
    public let url: String
    public let dataUpdatedAt: Date?
    public let data: LevelProgressionData
    
    private enum CodingKeys: String, CodingKey {
        case id, object, url
        case dataUpdatedAt = "data_updated_at"
        case data
    }
    
    public init(id: Int, object: String, url: String, dataUpdatedAt: Date?, data: LevelProgressionData) {
        self.id = id
        self.object = object
        self.url = url
        self.dataUpdatedAt = dataUpdatedAt
        self.data = data
    }
}

public struct LevelProgressionData: Codable, Equatable {
    public let createdAt: Date
    public let level: Int
    public let unlockedAt: Date?
    public let startedAt: Date?
    public let passedAt: Date?
    public let completedAt: Date?
    public let abandonedAt: Date?
    
    private enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case level
        case unlockedAt = "unlocked_at"
        case startedAt = "started_at"
        case passedAt = "passed_at"
        case completedAt = "completed_at"
        case abandonedAt = "abandoned_at"
    }
    
    public init(
        createdAt: Date,
        level: Int,
        unlockedAt: Date?,
        startedAt: Date?,
        passedAt: Date?,
        completedAt: Date?,
        abandonedAt: Date?
    ) {
        self.createdAt = createdAt
        self.level = level
        self.unlockedAt = unlockedAt
        self.startedAt = startedAt
        self.passedAt = passedAt
        self.completedAt = completedAt
        self.abandonedAt = abandonedAt
    }
}

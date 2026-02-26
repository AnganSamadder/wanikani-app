import Foundation

// MARK: - Study Material

public struct StudyMaterial: Codable, Equatable, Identifiable, Sendable {
    public let id: Int
    public let object: String
    public let url: String
    public let dataUpdatedAt: Date?
    public let data: StudyMaterialData

    private enum CodingKeys: String, CodingKey {
        case id, object, url, data
        case dataUpdatedAt = "data_updated_at"
    }

    public init(
        id: Int,
        object: String,
        url: String,
        dataUpdatedAt: Date?,
        data: StudyMaterialData
    ) {
        self.id = id
        self.object = object
        self.url = url
        self.dataUpdatedAt = dataUpdatedAt
        self.data = data
    }
}

public struct StudyMaterialData: Codable, Equatable, Sendable {
    public let createdAt: Date?
    public let subjectID: Int
    public let meaningNote: String?
    public let readingNote: String?
    public let meaningSynonyms: [String]
    public let hidden: Bool

    private enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case subjectID = "subject_id"
        case meaningNote = "meaning_note"
        case readingNote = "reading_note"
        case meaningSynonyms = "meaning_synonyms"
        case hidden
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        subjectID = try container.decode(Int.self, forKey: .subjectID)
        meaningNote = try container.decodeIfPresent(String.self, forKey: .meaningNote)
        readingNote = try container.decodeIfPresent(String.self, forKey: .readingNote)
        meaningSynonyms = try container.decodeIfPresent([String].self, forKey: .meaningSynonyms) ?? []
        hidden = try container.decodeIfPresent(Bool.self, forKey: .hidden) ?? false
    }

    public init(
        createdAt: Date?,
        subjectID: Int,
        meaningNote: String?,
        readingNote: String?,
        meaningSynonyms: [String],
        hidden: Bool = false
    ) {
        self.createdAt = createdAt
        self.subjectID = subjectID
        self.meaningNote = meaningNote
        self.readingNote = readingNote
        self.meaningSynonyms = meaningSynonyms
        self.hidden = hidden
    }
}

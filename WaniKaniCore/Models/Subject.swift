import Foundation

// MARK: - Subject Type

public enum SubjectType: String, Codable, Sendable {
    case radical
    case kanji
    case vocabulary
    case kanaVocabulary = "kana_vocabulary"
}

private extension KeyedDecodingContainer {
    func decodeArray<T: Decodable>(_ type: [T].Type, forKey key: Key) throws -> [T] {
        try decodeIfPresent(type, forKey: key) ?? []
    }
    
    func decodeString(forKey key: Key) throws -> String {
        try decodeIfPresent(String.self, forKey: key) ?? ""
    }

    func decodeBool(forKey key: Key, default defaultValue: Bool = false) throws -> Bool {
        try decodeIfPresent(Bool.self, forKey: key) ?? defaultValue
    }

    func decodeInt(forKey key: Key, default defaultValue: Int = 0) throws -> Int {
        try decodeIfPresent(Int.self, forKey: key) ?? defaultValue
    }
}

// MARK: - Common Types

public struct Meaning: Codable, Equatable {
    public let meaning: String
    public let primary: Bool
    public let acceptedAnswer: Bool
    
    private enum CodingKeys: String, CodingKey {
        case meaning, primary
        case acceptedAnswer = "accepted_answer"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        meaning = try container.decodeString(forKey: .meaning)
        primary = try container.decodeIfPresent(Bool.self, forKey: .primary) ?? false
        acceptedAnswer = try container.decodeIfPresent(Bool.self, forKey: .acceptedAnswer) ?? true
    }
    
    public init(meaning: String, primary: Bool, acceptedAnswer: Bool) {
        self.meaning = meaning
        self.primary = primary
        self.acceptedAnswer = acceptedAnswer
    }
}

public struct AuxiliaryMeaning: Codable, Equatable {
    public let meaning: String
    public let type: String
    
    private enum CodingKeys: String, CodingKey {
        case meaning, type
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        meaning = try container.decodeString(forKey: .meaning)
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "whitelist"
    }
    
    public init(meaning: String, type: String) {
        self.meaning = meaning
        self.type = type
    }
}

public struct Reading: Codable, Equatable {
    public let reading: String
    public let primary: Bool
    public let acceptedAnswer: Bool
    public let type: String?
    
    private enum CodingKeys: String, CodingKey {
        case reading, primary, type
        case acceptedAnswer = "accepted_answer"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reading = try container.decodeString(forKey: .reading)
        primary = try container.decodeIfPresent(Bool.self, forKey: .primary) ?? false
        acceptedAnswer = try container.decodeIfPresent(Bool.self, forKey: .acceptedAnswer) ?? true
        type = try container.decodeIfPresent(String.self, forKey: .type)
    }
    
    public init(reading: String, primary: Bool, acceptedAnswer: Bool, type: String? = nil) {
        self.reading = reading
        self.primary = primary
        self.acceptedAnswer = acceptedAnswer
        self.type = type
    }
}

public struct ContextSentence: Codable, Equatable {
    public let en: String
    public let ja: String
    
    private enum CodingKeys: String, CodingKey {
        case en, ja
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        en = try container.decodeString(forKey: .en)
        ja = try container.decodeString(forKey: .ja)
    }
    
    public init(en: String, ja: String) {
        self.en = en
        self.ja = ja
    }
}

public struct PronunciationAudio: Codable, Equatable {
    public let url: String
    public let contentType: String
    public let metadata: AudioMetadata?
    
    private enum CodingKeys: String, CodingKey {
        case url
        case contentType = "content_type"
        case metadata
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decodeString(forKey: .url)
        contentType = try container.decodeString(forKey: .contentType)
        if container.contains(.metadata) {
            metadata = try? container.decode(AudioMetadata.self, forKey: .metadata)
        } else {
            metadata = nil
        }
    }
    
    public init(url: String, contentType: String, metadata: AudioMetadata? = nil) {
        self.url = url
        self.contentType = contentType
        self.metadata = metadata
    }
}

public struct AudioMetadata: Codable, Equatable {
    public let gender: String
    public let sourceID: Int
    public let pronunciation: String
    public let voiceActorID: Int
    public let voiceActorName: String
    public let voiceDescription: String
    
    private enum CodingKeys: String, CodingKey {
        case gender, pronunciation
        case sourceID = "source_id"
        case voiceActorID = "voice_actor_id"
        case voiceActorName = "voice_actor_name"
        case voiceDescription = "voice_description"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gender = try container.decodeIfPresent(String.self, forKey: .gender) ?? ""
        sourceID = try container.decodeIfPresent(Int.self, forKey: .sourceID) ?? 0
        pronunciation = try container.decodeIfPresent(String.self, forKey: .pronunciation) ?? ""
        voiceActorID = try container.decodeIfPresent(Int.self, forKey: .voiceActorID) ?? 0
        voiceActorName = try container.decodeIfPresent(String.self, forKey: .voiceActorName) ?? ""
        voiceDescription = try container.decodeIfPresent(String.self, forKey: .voiceDescription) ?? ""
    }
    
    public init(
        gender: String,
        sourceID: Int,
        pronunciation: String,
        voiceActorID: Int,
        voiceActorName: String,
        voiceDescription: String
    ) {
        self.gender = gender
        self.sourceID = sourceID
        self.pronunciation = pronunciation
        self.voiceActorID = voiceActorID
        self.voiceActorName = voiceActorName
        self.voiceDescription = voiceDescription
    }
}

public struct CharacterImage: Codable, Equatable {
    public let url: String
    public let contentType: String
    public let metadata: ImageMetadata?
    
    private enum CodingKeys: String, CodingKey {
        case url
        case contentType = "content_type"
        case metadata
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decodeString(forKey: .url)
        contentType = try container.decodeString(forKey: .contentType)
        metadata = try container.decodeIfPresent(ImageMetadata.self, forKey: .metadata)
    }
    
    public init(url: String, contentType: String, metadata: ImageMetadata? = nil) {
        self.url = url
        self.contentType = contentType
        self.metadata = metadata
    }
}

public struct ImageMetadata: Codable, Equatable {
    public let inlineStyles: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case inlineStyles = "inline_styles"
    }
    
    public init(inlineStyles: Bool?) {
        self.inlineStyles = inlineStyles
    }
}

// MARK: - Radical

public struct Radical: Codable, Equatable, Identifiable {
    public let id: Int
    public let object: String
    public let url: String
    public let dataUpdatedAt: Date?
    public let data: RadicalData
    
    private enum CodingKeys: String, CodingKey {
        case id, object, url
        case dataUpdatedAt = "data_updated_at"
        case data
    }
    
    public init(id: Int, object: String, url: String, dataUpdatedAt: Date?, data: RadicalData) {
        self.id = id
        self.object = object
        self.url = url
        self.dataUpdatedAt = dataUpdatedAt
        self.data = data
    }
}

public struct RadicalData: Codable, Equatable {
    public let createdAt: Date
    public let level: Int
    public let slug: String
    public let hiddenAt: Date?
    public let documentURL: String
    public let characters: String?
    public let characterImages: [CharacterImage]
    public let meanings: [Meaning]
    public let auxiliaryMeanings: [AuxiliaryMeaning]
    public let amalgamationSubjectIDs: [Int]
    public let meaningMnemonic: String
    public let lessonPosition: Int
    public let spacedRepetitionSystemID: Int
    
    private enum CodingKeys: String, CodingKey {
        case level, slug, characters, meanings
        case createdAt = "created_at"
        case hiddenAt = "hidden_at"
        case documentURL = "document_url"
        case characterImages = "character_images"
        case auxiliaryMeanings = "auxiliary_meanings"
        case amalgamationSubjectIDs = "amalgamation_subject_ids"
        case meaningMnemonic = "meaning_mnemonic"
        case lessonPosition = "lesson_position"
        case spacedRepetitionSystemID = "spaced_repetition_system_id"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        level = try container.decode(Int.self, forKey: .level)
        slug = try container.decode(String.self, forKey: .slug)
        hiddenAt = try container.decodeIfPresent(Date.self, forKey: .hiddenAt)
        documentURL = try container.decode(String.self, forKey: .documentURL)
        characters = try container.decodeIfPresent(String.self, forKey: .characters)
        characterImages = try container.decodeArray([CharacterImage].self, forKey: .characterImages)
        meanings = try container.decodeArray([Meaning].self, forKey: .meanings)
        auxiliaryMeanings = try container.decodeArray([AuxiliaryMeaning].self, forKey: .auxiliaryMeanings)
        amalgamationSubjectIDs = try container.decodeArray([Int].self, forKey: .amalgamationSubjectIDs)
        meaningMnemonic = try container.decodeString(forKey: .meaningMnemonic)
        lessonPosition = try container.decode(Int.self, forKey: .lessonPosition)
        spacedRepetitionSystemID = try container.decode(Int.self, forKey: .spacedRepetitionSystemID)
    }
    
    public init(
        createdAt: Date,
        level: Int,
        slug: String,
        hiddenAt: Date? = nil,
        documentURL: String,
        characters: String?,
        characterImages: [CharacterImage],
        meanings: [Meaning],
        auxiliaryMeanings: [AuxiliaryMeaning],
        amalgamationSubjectIDs: [Int],
        meaningMnemonic: String,
        lessonPosition: Int,
        spacedRepetitionSystemID: Int
    ) {
        self.createdAt = createdAt
        self.level = level
        self.slug = slug
        self.hiddenAt = hiddenAt
        self.documentURL = documentURL
        self.characters = characters
        self.characterImages = characterImages
        self.meanings = meanings
        self.auxiliaryMeanings = auxiliaryMeanings
        self.amalgamationSubjectIDs = amalgamationSubjectIDs
        self.meaningMnemonic = meaningMnemonic
        self.lessonPosition = lessonPosition
        self.spacedRepetitionSystemID = spacedRepetitionSystemID
    }
}

// MARK: - Kanji

public struct Kanji: Codable, Equatable, Identifiable {
    public let id: Int
    public let object: String
    public let url: String
    public let dataUpdatedAt: Date?
    public let data: KanjiData
    
    private enum CodingKeys: String, CodingKey {
        case id, object, url
        case dataUpdatedAt = "data_updated_at"
        case data
    }
    
    public init(id: Int, object: String, url: String, dataUpdatedAt: Date?, data: KanjiData) {
        self.id = id
        self.object = object
        self.url = url
        self.dataUpdatedAt = dataUpdatedAt
        self.data = data
    }
}

public struct KanjiData: Codable, Equatable {
    public let createdAt: Date
    public let level: Int
    public let slug: String
    public let hiddenAt: Date?
    public let documentURL: String
    public let characters: String
    public let meanings: [Meaning]
    public let auxiliaryMeanings: [AuxiliaryMeaning]
    public let readings: [Reading]
    public let componentSubjectIDs: [Int]
    public let amalgamationSubjectIDs: [Int]
    public let visuallySimilarSubjectIDs: [Int]
    public let meaningMnemonic: String
    public let meaningHint: String?
    public let readingMnemonic: String
    public let readingHint: String?
    public let lessonPosition: Int
    public let spacedRepetitionSystemID: Int
    
    private enum CodingKeys: String, CodingKey {
        case level, slug, characters, meanings, readings
        case createdAt = "created_at"
        case hiddenAt = "hidden_at"
        case documentURL = "document_url"
        case auxiliaryMeanings = "auxiliary_meanings"
        case componentSubjectIDs = "component_subject_ids"
        case amalgamationSubjectIDs = "amalgamation_subject_ids"
        case visuallySimilarSubjectIDs = "visually_similar_subject_ids"
        case meaningMnemonic = "meaning_mnemonic"
        case meaningHint = "meaning_hint"
        case readingMnemonic = "reading_mnemonic"
        case readingHint = "reading_hint"
        case lessonPosition = "lesson_position"
        case spacedRepetitionSystemID = "spaced_repetition_system_id"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        level = try container.decode(Int.self, forKey: .level)
        slug = try container.decode(String.self, forKey: .slug)
        hiddenAt = try container.decodeIfPresent(Date.self, forKey: .hiddenAt)
        documentURL = try container.decode(String.self, forKey: .documentURL)
        characters = try container.decode(String.self, forKey: .characters)
        meanings = try container.decodeArray([Meaning].self, forKey: .meanings)
        auxiliaryMeanings = try container.decodeArray([AuxiliaryMeaning].self, forKey: .auxiliaryMeanings)
        readings = try container.decodeArray([Reading].self, forKey: .readings)
        componentSubjectIDs = try container.decodeArray([Int].self, forKey: .componentSubjectIDs)
        amalgamationSubjectIDs = try container.decodeArray([Int].self, forKey: .amalgamationSubjectIDs)
        visuallySimilarSubjectIDs = try container.decodeArray([Int].self, forKey: .visuallySimilarSubjectIDs)
        meaningMnemonic = try container.decodeString(forKey: .meaningMnemonic)
        meaningHint = try container.decodeIfPresent(String.self, forKey: .meaningHint)
        readingMnemonic = try container.decodeString(forKey: .readingMnemonic)
        readingHint = try container.decodeIfPresent(String.self, forKey: .readingHint)
        lessonPosition = try container.decode(Int.self, forKey: .lessonPosition)
        spacedRepetitionSystemID = try container.decode(Int.self, forKey: .spacedRepetitionSystemID)
    }
    
    public init(
        createdAt: Date,
        level: Int,
        slug: String,
        hiddenAt: Date? = nil,
        documentURL: String,
        characters: String,
        meanings: [Meaning],
        auxiliaryMeanings: [AuxiliaryMeaning],
        readings: [Reading],
        componentSubjectIDs: [Int],
        amalgamationSubjectIDs: [Int],
        visuallySimilarSubjectIDs: [Int],
        meaningMnemonic: String,
        meaningHint: String?,
        readingMnemonic: String,
        readingHint: String?,
        lessonPosition: Int,
        spacedRepetitionSystemID: Int
    ) {
        self.createdAt = createdAt
        self.level = level
        self.slug = slug
        self.hiddenAt = hiddenAt
        self.documentURL = documentURL
        self.characters = characters
        self.meanings = meanings
        self.auxiliaryMeanings = auxiliaryMeanings
        self.readings = readings
        self.componentSubjectIDs = componentSubjectIDs
        self.amalgamationSubjectIDs = amalgamationSubjectIDs
        self.visuallySimilarSubjectIDs = visuallySimilarSubjectIDs
        self.meaningMnemonic = meaningMnemonic
        self.meaningHint = meaningHint
        self.readingMnemonic = readingMnemonic
        self.readingHint = readingHint
        self.lessonPosition = lessonPosition
        self.spacedRepetitionSystemID = spacedRepetitionSystemID
    }
}

// MARK: - Vocabulary

public struct Vocabulary: Codable, Equatable, Identifiable {
    public let id: Int
    public let object: String
    public let url: String
    public let dataUpdatedAt: Date?
    public let data: VocabularyData
    
    private enum CodingKeys: String, CodingKey {
        case id, object, url
        case dataUpdatedAt = "data_updated_at"
        case data
    }
    
    public init(id: Int, object: String, url: String, dataUpdatedAt: Date?, data: VocabularyData) {
        self.id = id
        self.object = object
        self.url = url
        self.dataUpdatedAt = dataUpdatedAt
        self.data = data
    }
}

public struct VocabularyData: Codable, Equatable {
    public let createdAt: Date
    public let level: Int
    public let slug: String
    public let hiddenAt: Date?
    public let documentURL: String
    public let characters: String
    public let meanings: [Meaning]
    public let auxiliaryMeanings: [AuxiliaryMeaning]
    public let readings: [Reading]
    public let partsOfSpeech: [String]
    public let componentSubjectIDs: [Int]
    public let meaningMnemonic: String
    public let readingMnemonic: String
    public let contextSentences: [ContextSentence]
    public let pronunciationAudios: [PronunciationAudio]
    public let lessonPosition: Int
    public let spacedRepetitionSystemID: Int
    
    private enum CodingKeys: String, CodingKey {
        case level, slug, characters, meanings, readings
        case createdAt = "created_at"
        case hiddenAt = "hidden_at"
        case documentURL = "document_url"
        case auxiliaryMeanings = "auxiliary_meanings"
        case partsOfSpeech = "parts_of_speech"
        case componentSubjectIDs = "component_subject_ids"
        case meaningMnemonic = "meaning_mnemonic"
        case readingMnemonic = "reading_mnemonic"
        case contextSentences = "context_sentences"
        case pronunciationAudios = "pronunciation_audios"
        case lessonPosition = "lesson_position"
        case spacedRepetitionSystemID = "spaced_repetition_system_id"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        level = try container.decode(Int.self, forKey: .level)
        slug = try container.decode(String.self, forKey: .slug)
        hiddenAt = try container.decodeIfPresent(Date.self, forKey: .hiddenAt)
        documentURL = try container.decode(String.self, forKey: .documentURL)
        characters = try container.decode(String.self, forKey: .characters)
        meanings = try container.decodeArray([Meaning].self, forKey: .meanings)
        auxiliaryMeanings = try container.decodeArray([AuxiliaryMeaning].self, forKey: .auxiliaryMeanings)
        readings = try container.decodeArray([Reading].self, forKey: .readings)
        partsOfSpeech = try container.decodeArray([String].self, forKey: .partsOfSpeech)
        componentSubjectIDs = try container.decodeArray([Int].self, forKey: .componentSubjectIDs)
        meaningMnemonic = try container.decodeString(forKey: .meaningMnemonic)
        readingMnemonic = try container.decodeString(forKey: .readingMnemonic)
        contextSentences = try container.decodeArray([ContextSentence].self, forKey: .contextSentences)
        pronunciationAudios = try container.decodeArray([PronunciationAudio].self, forKey: .pronunciationAudios)
        lessonPosition = try container.decode(Int.self, forKey: .lessonPosition)
        spacedRepetitionSystemID = try container.decode(Int.self, forKey: .spacedRepetitionSystemID)
    }
    
    public init(
        createdAt: Date,
        level: Int,
        slug: String,
        hiddenAt: Date? = nil,
        documentURL: String,
        characters: String,
        meanings: [Meaning],
        auxiliaryMeanings: [AuxiliaryMeaning],
        readings: [Reading],
        partsOfSpeech: [String],
        componentSubjectIDs: [Int],
        meaningMnemonic: String,
        readingMnemonic: String,
        contextSentences: [ContextSentence],
        pronunciationAudios: [PronunciationAudio],
        lessonPosition: Int,
        spacedRepetitionSystemID: Int
    ) {
        self.createdAt = createdAt
        self.level = level
        self.slug = slug
        self.hiddenAt = hiddenAt
        self.documentURL = documentURL
        self.characters = characters
        self.meanings = meanings
        self.auxiliaryMeanings = auxiliaryMeanings
        self.readings = readings
        self.partsOfSpeech = partsOfSpeech
        self.componentSubjectIDs = componentSubjectIDs
        self.meaningMnemonic = meaningMnemonic
        self.readingMnemonic = readingMnemonic
        self.contextSentences = contextSentences
        self.pronunciationAudios = pronunciationAudios
        self.lessonPosition = lessonPosition
        self.spacedRepetitionSystemID = spacedRepetitionSystemID
    }
}

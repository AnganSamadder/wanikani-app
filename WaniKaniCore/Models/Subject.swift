import Foundation

// MARK: - Subject Type

public enum SubjectType: String, Codable {
    case radical
    case kanji
    case vocabulary
    case kanaVocabulary = "kana_vocabulary"
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
    
    public init(meaning: String, primary: Bool, acceptedAnswer: Bool) {
        self.meaning = meaning
        self.primary = primary
        self.acceptedAnswer = acceptedAnswer
    }
}

public struct AuxiliaryMeaning: Codable, Equatable {
    public let meaning: String
    public let type: String
    
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
    
    public init(en: String, ja: String) {
        self.en = en
        self.ja = ja
    }
}

public struct PronunciationAudio: Codable, Equatable {
    public let url: String
    public let contentType: String
    public let metadata: AudioMetadata
    
    private enum CodingKeys: String, CodingKey {
        case url
        case contentType = "content_type"
        case metadata
    }
    
    public init(url: String, contentType: String, metadata: AudioMetadata) {
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

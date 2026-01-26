import Foundation

// MARK: - Summary

public struct Summary: Codable, Equatable {
    public let object: String
    public let url: String
    public let dataUpdatedAt: Date?
    public let data: SummaryData
    
    private enum CodingKeys: String, CodingKey {
        case object, url
        case dataUpdatedAt = "data_updated_at"
        case data
    }
    
    public init(object: String, url: String, dataUpdatedAt: Date?, data: SummaryData) {
        self.object = object
        self.url = url
        self.dataUpdatedAt = dataUpdatedAt
        self.data = data
    }
}

public struct SummaryData: Codable, Equatable {
    public let lessons: [LessonSummary]
    public let reviews: [ReviewSummary]
    public let nextReviewsAt: Date?
    
    public var availableLessonsCount: Int {
        lessons.first(where: { $0.availableAt <= Date() })?.subjectIDs.count ?? 0
    }
    
    public var availableReviewsCount: Int {
        reviews.first(where: { $0.availableAt <= Date() })?.subjectIDs.count ?? 0
    }
    
    private enum CodingKeys: String, CodingKey {
        case lessons, reviews
        case nextReviewsAt = "next_reviews_at"
    }
    
    public init(lessons: [LessonSummary], reviews: [ReviewSummary], nextReviewsAt: Date?) {
        self.lessons = lessons
        self.reviews = reviews
        self.nextReviewsAt = nextReviewsAt
    }
}

// MARK: - Lesson Summary

public struct LessonSummary: Codable, Equatable {
    public let availableAt: Date
    public let subjectIDs: [Int]
    
    private enum CodingKeys: String, CodingKey {
        case availableAt = "available_at"
        case subjectIDs = "subject_ids"
    }
    
    public init(availableAt: Date, subjectIDs: [Int]) {
        self.availableAt = availableAt
        self.subjectIDs = subjectIDs
    }
}

// MARK: - Review Summary

public struct ReviewSummary: Codable, Equatable {
    public let availableAt: Date
    public let subjectIDs: [Int]
    
    private enum CodingKeys: String, CodingKey {
        case availableAt = "available_at"
        case subjectIDs = "subject_ids"
    }
    
    public init(availableAt: Date, subjectIDs: [Int]) {
        self.availableAt = availableAt
        self.subjectIDs = subjectIDs
    }
}

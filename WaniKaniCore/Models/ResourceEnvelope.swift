import Foundation

// MARK: - Single Resource Envelope

public struct ResourceEnvelope<T: Decodable>: Decodable {
    public let object: String
    public let url: String
    public let dataUpdatedAt: Date?
    public let data: T
    
    private enum CodingKeys: String, CodingKey {
        case object, url
        case dataUpdatedAt = "data_updated_at"
        case data
    }
}

// MARK: - Collection Pagination

public struct CollectionPage: Decodable, Equatable {
    public let perPage: Int
    public let nextURL: String?
    public let previousURL: String?
    
    private enum CodingKeys: String, CodingKey {
        case perPage = "per_page"
        case nextURL = "next_url"
        case previousURL = "previous_url"
    }
}

// MARK: - Collection Envelope

public struct CollectionEnvelope<T: Decodable>: Decodable {
    public let object: String
    public let url: String
    public let pages: CollectionPage
    public let totalCount: Int
    public let dataUpdatedAt: Date?
    public let data: [T]
    
    private enum CodingKeys: String, CodingKey {
        case object, url, pages
        case totalCount = "total_count"
        case dataUpdatedAt = "data_updated_at"
        case data
    }
}

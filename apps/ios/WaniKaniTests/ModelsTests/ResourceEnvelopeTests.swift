import XCTest
@testable import WaniKaniCore

final class ResourceEnvelopeTests: XCTestCase {
    
    private var decoder: JSONDecoder!
    
    override func setUp() {
        super.setUp()
        decoder = .wanikaniDecoder()
    }
    
    func test_resourceEnvelope_decodesFromJSON() throws {
        let json = """
        {
            "object": "assignment",
            "url": "https://api.wanikani.com/v2/assignments/12345",
            "data_updated_at": "2023-10-27T15:45:00.000Z",
            "data": {
                "id": 12345,
                "value": "test"
            }
        }
        """.data(using: .utf8)!
        
        struct TestData: Decodable {
            let id: Int
            let value: String
        }
        
        let envelope = try decoder.decode(ResourceEnvelope<TestData>.self, from: json)
        
        XCTAssertEqual(envelope.object, "assignment")
        XCTAssertEqual(envelope.url, "https://api.wanikani.com/v2/assignments/12345")
        XCTAssertNotNil(envelope.dataUpdatedAt)
        XCTAssertEqual(envelope.data.id, 12345)
        XCTAssertEqual(envelope.data.value, "test")
    }
    
    func test_collectionEnvelope_decodesFromJSON() throws {
        let json = """
        {
            "object": "collection",
            "url": "https://api.wanikani.com/v2/subjects",
            "pages": {
                "per_page": 500,
                "next_url": "https://api.wanikani.com/v2/subjects?after_id=500",
                "previous_url": null
            },
            "total_count": 9400,
            "data_updated_at": "2023-10-27T15:45:00.000Z",
            "data": [
                {"id": 1, "name": "test1"},
                {"id": 2, "name": "test2"}
            ]
        }
        """.data(using: .utf8)!
        
        struct TestItem: Decodable {
            let id: Int
            let name: String
        }
        
        let envelope = try decoder.decode(CollectionEnvelope<TestItem>.self, from: json)
        
        XCTAssertEqual(envelope.object, "collection")
        XCTAssertEqual(envelope.totalCount, 9400)
        XCTAssertEqual(envelope.pages.perPage, 500)
        XCTAssertEqual(envelope.pages.nextURL, "https://api.wanikani.com/v2/subjects?after_id=500")
        XCTAssertNil(envelope.pages.previousURL)
        XCTAssertEqual(envelope.data.count, 2)
        XCTAssertEqual(envelope.data.first?.id, 1)
    }
    
    func test_collectionPage_decodesWithNullURLs() throws {
        let json = """
        {
            "per_page": 100,
            "next_url": null,
            "previous_url": null
        }
        """.data(using: .utf8)!
        
        let page = try decoder.decode(CollectionPage.self, from: json)
        
        XCTAssertEqual(page.perPage, 100)
        XCTAssertNil(page.nextURL)
        XCTAssertNil(page.previousURL)
    }
}

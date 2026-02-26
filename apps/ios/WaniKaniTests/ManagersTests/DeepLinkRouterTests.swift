import XCTest
@testable import WaniKaniCore

final class DeepLinkRouterTests: XCTestCase {
    
    var router: DeepLinkRouter!
    
    override func setUp() {
        super.setUp()
        router = DeepLinkRouter()
    }
    
    override func tearDown() {
        router = nil
        super.tearDown()
    }
    
    func test_parseCustomScheme_dashboard() {
        let url = URL(string: "wanikani://dashboard")!
        let result = router.parse(url: url)
        XCTAssertEqual(result, .dashboard)
    }
    
    func test_parseCustomScheme_reviews() {
        let url = URL(string: "wanikani://reviews")!
        let result = router.parse(url: url)
        XCTAssertEqual(result, .reviews)
    }
    
    func test_parseCustomScheme_lessons() {
        let url = URL(string: "wanikani://lessons")!
        let result = router.parse(url: url)
        XCTAssertEqual(result, .lessons)
    }
    
    func test_parseCustomScheme_subject() {
        let url = URL(string: "wanikani://subject/123")!
        let result = router.parse(url: url)
        XCTAssertEqual(result, .subject(id: 123))
    }
    
    func test_parseCustomScheme_level() {
        let url = URL(string: "wanikani://level/5")!
        let result = router.parse(url: url)
        XCTAssertEqual(result, .level(number: 5))
    }
    
    func test_parseCustomScheme_settings() {
        let url = URL(string: "wanikani://settings")!
        let result = router.parse(url: url)
        XCTAssertEqual(result, .settings)
    }
    
    func test_parseCustomScheme_userScript() {
        let url = URL(string: "wanikani://script/42")!
        let result = router.parse(url: url)
        XCTAssertEqual(result, .userScript(id: 42))
    }
    
    func test_parseCustomScheme_unknown() {
        let url = URL(string: "wanikani://unknown")!
        let result = router.parse(url: url)
        XCTAssertEqual(result, .unknown(url))
    }
    
    func test_parseUniversalLink_dashboard() {
        let url = URL(string: "https://www.wanikani.com/dashboard")!
        let result = router.parse(url: url)
        XCTAssertEqual(result, .dashboard)
    }
    
    func test_parseUniversalLink_rootAssumesDashboard() {
        let url = URL(string: "https://www.wanikani.com/")!
        let result = router.parse(url: url)
        XCTAssertEqual(result, .dashboard)
    }
    
    func test_parseUniversalLink_reviews() {
        let url = URL(string: "https://www.wanikani.com/review")!
        let result = router.parse(url: url)
        XCTAssertEqual(result, .reviews)
    }
    
    func test_parseUniversalLink_lessons() {
        let url = URL(string: "https://www.wanikani.com/lesson")!
        let result = router.parse(url: url)
        XCTAssertEqual(result, .lessons)
    }
    
    func test_parseUniversalLink_level() {
        let url = URL(string: "https://www.wanikani.com/level/10")!
        let result = router.parse(url: url)
        XCTAssertEqual(result, .level(number: 10))
    }
    
    func test_parseUniversalLink_settings() {
        let url = URL(string: "https://www.wanikani.com/settings")!
        let result = router.parse(url: url)
        XCTAssertEqual(result, .settings)
    }
    
    func test_parseUniversalLink_radicals_returnsUnknown() {
        let url = URL(string: "https://www.wanikani.com/radicals/ground")!
        let result = router.parse(url: url)
        XCTAssertEqual(result, .unknown(url))
    }
    
    func test_parseUniversalLink_kanji_returnsUnknown() {
        let url = URL(string: "https://www.wanikani.com/kanji/%E4%B8%80")!
        let result = router.parse(url: url)
        XCTAssertEqual(result, .unknown(url))
    }
    
    func test_parseUniversalLink_vocabulary_returnsUnknown() {
        let url = URL(string: "https://www.wanikani.com/vocabulary/%E4%B8%80%E3%81%A4")!
        let result = router.parse(url: url)
        XCTAssertEqual(result, .unknown(url))
    }
    
    func test_parseUniversalLink_withoutWWW() {
        let url = URL(string: "https://wanikani.com/dashboard")!
        let result = router.parse(url: url)
        XCTAssertEqual(result, .dashboard)
    }
    
    func test_parseUnknownScheme() {
        let url = URL(string: "https://example.com/")!
        let result = router.parse(url: url)
        XCTAssertEqual(result, .unknown(url))
    }
    
    func test_urlGeneration_dashboard() {
        let url = router.url(for: .dashboard)
        XCTAssertEqual(url?.absoluteString, "wanikani://dashboard")
    }
    
    func test_urlGeneration_reviews() {
        let url = router.url(for: .reviews)
        XCTAssertEqual(url?.absoluteString, "wanikani://reviews")
    }
    
    func test_urlGeneration_lessons() {
        let url = router.url(for: .lessons)
        XCTAssertEqual(url?.absoluteString, "wanikani://lessons")
    }
    
    func test_urlGeneration_subject() {
        let url = router.url(for: .subject(id: 999))
        XCTAssertEqual(url?.absoluteString, "wanikani://subject/999")
    }
    
    func test_urlGeneration_level() {
        let url = router.url(for: .level(number: 20))
        XCTAssertEqual(url?.absoluteString, "wanikani://level/20")
    }
    
    func test_urlGeneration_settings() {
        let url = router.url(for: .settings)
        XCTAssertEqual(url?.absoluteString, "wanikani://settings")
    }
    
    func test_urlGeneration_userScript() {
        let url = router.url(for: .userScript(id: 7))
        XCTAssertEqual(url?.absoluteString, "wanikani://script/7")
    }
    
    func test_urlGeneration_unknown_returnsNil() {
        let unknownURL = URL(string: "https://example.com")!
        let url = router.url(for: .unknown(unknownURL))
        XCTAssertNil(url)
    }
}

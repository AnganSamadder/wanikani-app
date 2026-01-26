import XCTest
@testable import WaniKaniCore

// MARK: - Mock URLProtocol

final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            XCTFail("No request handler set")
            return
        }
        
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {}
}

// MARK: - Test Model

struct TestResponse: Codable, Equatable {
    let id: Int
    let name: String
}

// MARK: - Tests

final class NetworkClientTests: XCTestCase {
    private var sut: URLSessionNetworkClient!
    private var session: URLSession!
    
    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: configuration)
        sut = URLSessionNetworkClient(
            baseURL: URL(string: "https://api.test.com")!,
            session: session
        )
    }
    
    override func tearDown() {
        sut = nil
        session = nil
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }
    
    // MARK: - Success Cases
    
    func test_request_success_returnsDecodedResponse() async throws {
        // Given
        let expectedResponse = TestResponse(id: 1, name: "Test")
        let jsonData = try JSONEncoder().encode(expectedResponse)
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, jsonData)
        }
        
        let endpoint = Endpoint(path: "/test")
        
        // When
        let result: TestResponse = try await sut.request(endpoint)
        
        // Then
        XCTAssertEqual(result, expectedResponse)
    }
    
    func test_request_withQueryParameters_buildsCorrectURL() async throws {
        // Given
        let expectedResponse = TestResponse(id: 1, name: "Test")
        let jsonData = try JSONEncoder().encode(expectedResponse)
        var capturedURL: URL?
        
        MockURLProtocol.requestHandler = { request in
            capturedURL = request.url
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, jsonData)
        }
        
        let endpoint = Endpoint(
            path: "/subjects",
            queryParameters: ["level": "5", "types": "kanji"]
        )
        
        // When
        let _: TestResponse = try await sut.request(endpoint)
        
        // Then
        XCTAssertNotNil(capturedURL)
        let components = URLComponents(url: capturedURL!, resolvingAgainstBaseURL: true)
        let queryItems = components?.queryItems ?? []
        XCTAssertTrue(queryItems.contains(URLQueryItem(name: "level", value: "5")))
        XCTAssertTrue(queryItems.contains(URLQueryItem(name: "types", value: "kanji")))
    }
    
    func test_request_withHeaders_sendsHeaders() async throws {
        // Given
        let expectedResponse = TestResponse(id: 1, name: "Test")
        let jsonData = try JSONEncoder().encode(expectedResponse)
        var capturedRequest: URLRequest?
        
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, jsonData)
        }
        
        let endpoint = Endpoint(
            path: "/test",
            headers: ["Authorization": "Bearer token123", "Wanikani-Revision": "20170710"]
        )
        
        // When
        let _: TestResponse = try await sut.request(endpoint)
        
        // Then
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer token123")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Wanikani-Revision"), "20170710")
    }
    
    // MARK: - Error Cases
    
    func test_request_unauthorized_throwsUnauthorizedError() async {
        // Given
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }
        
        let endpoint = Endpoint(path: "/test")
        
        // When/Then
        do {
            let _: TestResponse = try await sut.request(endpoint)
            XCTFail("Expected unauthorized error")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.unauthorized)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func test_request_rateLimited_throwsRateLimitedError() async {
        // Given
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 429,
                httpVersion: nil,
                headerFields: ["Retry-After": "30"]
            )!
            return (response, Data())
        }
        
        let endpoint = Endpoint(path: "/test")
        
        // When/Then
        do {
            let _: TestResponse = try await sut.request(endpoint)
            XCTFail("Expected rate limited error")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.rateLimited(retryAfter: 30))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func test_request_rateLimited_defaultsTo60WhenNoHeader() async {
        // Given
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 429,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }
        
        let endpoint = Endpoint(path: "/test")
        
        // When/Then
        do {
            let _: TestResponse = try await sut.request(endpoint)
            XCTFail("Expected rate limited error")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.rateLimited(retryAfter: 60))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func test_request_serverError_throwsServerError() async {
        // Given
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 503,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }
        
        let endpoint = Endpoint(path: "/test")
        
        // When/Then
        do {
            let _: TestResponse = try await sut.request(endpoint)
            XCTFail("Expected server error")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.serverError(statusCode: 503))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func test_request_networkFailure_throwsNoConnectionError() async {
        // Given
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        
        let endpoint = Endpoint(path: "/test")
        
        // When/Then
        do {
            let _: TestResponse = try await sut.request(endpoint)
            XCTFail("Expected no connection error")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.noConnection)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func test_request_invalidJSON_throwsDecodingError() async {
        // Given
        let invalidJSON = "not valid json".data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, invalidJSON)
        }
        
        let endpoint = Endpoint(path: "/test")
        
        // When/Then
        do {
            let _: TestResponse = try await sut.request(endpoint)
            XCTFail("Expected decoding error")
        } catch let error as NetworkError {
            if case .decodingFailed = error {
                // Success
            } else {
                XCTFail("Expected decodingFailed error, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - HTTP Method Tests
    
    func test_request_postMethod_setsCorrectHTTPMethod() async throws {
        // Given
        let expectedResponse = TestResponse(id: 1, name: "Test")
        let jsonData = try JSONEncoder().encode(expectedResponse)
        var capturedRequest: URLRequest?
        
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, jsonData)
        }
        
        let endpoint = Endpoint(path: "/test", method: .post)
        
        // When
        let _: TestResponse = try await sut.request(endpoint)
        
        // Then
        XCTAssertEqual(capturedRequest?.httpMethod, "POST")
    }
}

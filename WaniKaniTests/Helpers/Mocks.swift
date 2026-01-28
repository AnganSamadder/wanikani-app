import Foundation
import WaniKaniCore

// MARK: - MockNetworkClient
public final class MockNetworkClient: NetworkClient, @unchecked Sendable {
    public var responses: [Any] = []
    public var capturedEndpoints: [Endpoint] = []
    private var callIndex = 0

    public init() {}

    public func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        capturedEndpoints.append(endpoint)
        
        guard callIndex < responses.count else {
            throw NSError(domain: "MockNetworkClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "No more responses configured"])
        }

        let response = responses[callIndex]
        callIndex += 1

        if let error = response as? Error {
            throw error
        }

        guard let typedResponse = response as? T else {
            throw NSError(domain: "MockNetworkClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Type mismatch. Expected \(T.self), got \(type(of: response))"])
        }

        return typedResponse
    }
}

// MARK: - MockSummaryRepository
public final class MockSummaryRepository: SummaryRepositoryProtocol, @unchecked Sendable {
    public var mockSummary: Summary?
    public var error: Error?

    public init() {}

    public func fetchSummary() async throws -> Summary {
        if let error = error { throw error }
        guard let mockSummary = mockSummary else {
            throw NSError(domain: "MockSummaryRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "Mock summary not set"])
        }
        return mockSummary
    }
}

// MARK: - MockSubjectRepository
public final class MockSubjectRepository: SubjectRepositoryProtocol, @unchecked Sendable {
    public var mockSubject: PersistentSubject?
    public var error: Error?

    public init() {}

    public func fetchSubject(id: Int) async throws -> PersistentSubject? {
        if let error = error { throw error }
        return mockSubject
    }
}

// MARK: - MockAssignmentRepository
public final class MockAssignmentRepository: AssignmentRepositoryProtocol, @unchecked Sendable {
    public var mockAssignments: [PersistentAssignment] = []
    public var mockAssignment: PersistentAssignment?
    public var error: Error?

    public init() {}

    public func fetchAssignments(availableBefore: Date) async throws -> [PersistentAssignment] {
        if let error = error { throw error }
        return mockAssignments
    }

    public func fetchAssignment(id: Int) async throws -> PersistentAssignment? {
        if let error = error { throw error }
        return mockAssignment
    }
}

// MARK: - MockReviewRepository
public final class MockReviewRepository: ReviewRepositoryProtocol, @unchecked Sendable {
    public var mockReview: Review?
    public var error: Error?

    public init() {}

    public func submitReview(
        assignmentId: Int,
        incorrectMeaningAnswers: Int,
        incorrectReadingAnswers: Int
    ) async throws -> Review {
        if let error = error { throw error }
        guard let mockReview = mockReview else {
            throw NSError(domain: "MockReviewRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "Mock review not set"])
        }
        return mockReview
    }
}

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
    public var mockSubject: SubjectSnapshot?
    public var mockSubjects: [SubjectSnapshot] = []
    public var error: Error?

    public init() {}

    public func fetchSubject(id: Int) async throws -> SubjectSnapshot? {
        if let error = error { throw error }
        return mockSubject
    }

    public func fetchSubjects(ids: [Int]) async throws -> [SubjectSnapshot] {
        if let error = error { throw error }
        return mockSubjects.filter { ids.contains($0.id) }
    }
}

// MARK: - MockAssignmentRepository
public final class MockAssignmentRepository: AssignmentRepositoryProtocol, @unchecked Sendable {
    public var mockAssignments: [AssignmentSnapshot] = []
    public var mockAssignment: AssignmentSnapshot?
    public var error: Error?

    public init() {}

    public func fetchAssignments(availableBefore: Date) async throws -> [AssignmentSnapshot] {
        if let error = error { throw error }
        return mockAssignments
    }

    public func fetchAssignment(id: Int) async throws -> AssignmentSnapshot? {
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

// MARK: - App Repositories
public final class MockDashboardRepository: DashboardRepositoryProtocol, @unchecked Sendable {
    public var mockSummary: Summary?
    public var error: Error?

    public init() {}

    public func fetchDashboardSummary() async throws -> Summary {
        if let error = error { throw error }
        guard let mockSummary = mockSummary else {
            throw NSError(domain: "MockDashboardRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "Mock summary not set"])
        }
        return mockSummary
    }
}

public final class MockReviewSessionRepository: ReviewSessionRepositoryProtocol, @unchecked Sendable {
    public var mockAssignments: [AssignmentSnapshot] = []
    public var mockReview: Review?
    public var error: Error?
    public var pendingReviews: [Int: PendingReviewSnapshot] = [:]
    public var studyMaterials: [Int: StudyMaterialSnapshot] = [:]
    public var activeQueueItems: [String: ActiveQueueItemSnapshot] = [:]  // keyed by "\(assignmentID)-\(questionType)"
    public var submitReviewCalls: [(assignmentId: Int, incorrectMeaningAnswers: Int, incorrectReadingAnswers: Int)] = []
    public var startReviewSessionCallCount = 0
    public var startReviewSessionDelayNanoseconds: UInt64 = 0

    public init() {}

    public func startReviewSession() async throws -> [AssignmentSnapshot] {
        if let error = error { throw error }
        startReviewSessionCallCount += 1
        if startReviewSessionDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: startReviewSessionDelayNanoseconds)
        }
        return mockAssignments
    }

    public func submitReview(
        assignmentId: Int,
        incorrectMeaningAnswers: Int,
        incorrectReadingAnswers: Int
    ) async throws -> Review {
        if let error = error { throw error }
        submitReviewCalls.append((
            assignmentId: assignmentId,
            incorrectMeaningAnswers: incorrectMeaningAnswers,
            incorrectReadingAnswers: incorrectReadingAnswers
        ))
        guard let mockReview = mockReview else {
            throw NSError(domain: "MockReviewSessionRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "Mock review not set"])
        }
        return mockReview
    }

    public func fetchPendingReviews() async throws -> [PendingReviewSnapshot] {
        if let error = error { throw error }
        return Array(pendingReviews.values)
    }

    public func upsertPendingReview(_ pending: PendingReviewSnapshot) async throws {
        if let error = error { throw error }
        pendingReviews[pending.assignmentID] = pending
    }

    public func deletePendingReview(assignmentId: Int) async throws {
        if let error = error { throw error }
        pendingReviews.removeValue(forKey: assignmentId)
    }

    public func countHalfCompletions() async throws -> Int {
        if let error = error { throw error }
        return pendingReviews.values.filter(\.isHalfComplete).count
    }

    public func prunePendingReviews(validAssignmentIDs: Set<Int>) async throws {
        if let error = error { throw error }
        pendingReviews = pendingReviews.filter { validAssignmentIDs.contains($0.key) }
    }

    public func fetchStudyMaterial(subjectID: Int) async throws -> StudyMaterialSnapshot? {
        if let error = error { throw error }
        return studyMaterials[subjectID]
    }

    public func fetchActiveQueueItems() async throws -> [ActiveQueueItemSnapshot] {
        if let error = error { throw error }
        return Array(activeQueueItems.values)
    }

    public func upsertActiveQueueItem(_ item: ActiveQueueItemSnapshot) async throws {
        if let error = error { throw error }
        let key = "\(item.assignmentID)-\(item.questionType)"
        activeQueueItems[key] = item
    }

    public func deleteActiveQueueItem(assignmentID: Int, questionType: String) async throws {
        if let error = error { throw error }
        activeQueueItems.removeValue(forKey: "\(assignmentID)-\(questionType)")
    }

    public func clearActiveQueue() async throws {
        if let error = error { throw error }
        activeQueueItems.removeAll()
    }

    public func pruneActiveQueue(validAssignmentIDs: Set<Int>) async throws {
        if let error = error { throw error }
        activeQueueItems = activeQueueItems.filter { key, _ in
            let parts = key.split(separator: "-", maxSplits: 1)
            guard let idStr = parts.first, let id = Int(idStr) else { return false }
            return validAssignmentIDs.contains(id)
        }
    }
}

public final class MockLessonSessionRepository: LessonSessionRepositoryProtocol, @unchecked Sendable {
    public var mockQueue: [SubjectSnapshot] = []
    public var error: Error?
    public var fetchLessonQueueCallCount = 0
    public var fetchLessonQueueDelayNanoseconds: UInt64 = 0

    public init() {}

    public func fetchLessonQueue() async throws -> [SubjectSnapshot] {
        if let error = error { throw error }
        fetchLessonQueueCallCount += 1
        if fetchLessonQueueDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: fetchLessonQueueDelayNanoseconds)
        }
        return mockQueue
    }
}

public final class MockSubjectDetailRepository: SubjectDetailRepositoryProtocol, @unchecked Sendable {
    public var subjectsByID: [Int: SubjectSnapshot] = [:]
    public var error: Error?
    public var fetchSubjectDetailCalls: [Int] = []

    public init() {}

    public func fetchSubjectDetail(id: Int) async throws -> SubjectSnapshot? {
        if let error = error { throw error }
        fetchSubjectDetailCalls.append(id)
        return subjectsByID[id]
    }
}

public final class MockSubjectRelationsRepository: SubjectRelationsRepositoryProtocol, @unchecked Sendable {
    public var subjectsByID: [Int: SubjectSnapshot] = [:]
    public var error: Error?
    public var fetchSubjectDetailsCalls: [[Int]] = []

    public init() {}

    public func fetchSubjectDetails(ids: [Int]) async throws -> [SubjectSnapshot] {
        if let error = error { throw error }
        fetchSubjectDetailsCalls.append(ids)
        return ids.compactMap { subjectsByID[$0] }
    }
}

public final class MockStudyMaterialRepository: StudyMaterialRepositoryProtocol, @unchecked Sendable {
    public var materialsBySubjectID: [Int: StudyMaterialSnapshot] = [:]
    public var error: Error?

    public init() {}

    public func syncStudyMaterials(subjectIDs: [Int]?) async throws {
        if let error = error { throw error }
    }

    public func fetchStudyMaterial(subjectID: Int) async throws -> StudyMaterialSnapshot? {
        if let error = error { throw error }
        return materialsBySubjectID[subjectID]
    }

    public func upsertStudyMaterial(
        subjectID: Int,
        meaningNote: String?,
        readingNote: String?,
        meaningSynonyms: [String]
    ) async throws -> StudyMaterialSnapshot {
        if let error = error { throw error }
        let snapshot = StudyMaterialSnapshot(
            subjectID: subjectID,
            meaningNote: meaningNote,
            readingNote: readingNote,
            meaningSynonyms: meaningSynonyms,
            updatedAt: Date()
        )
        materialsBySubjectID[subjectID] = snapshot
        return snapshot
    }
}

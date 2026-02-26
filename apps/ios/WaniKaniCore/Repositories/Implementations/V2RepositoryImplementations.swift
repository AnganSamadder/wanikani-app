import Foundation

@MainActor
public final class DashboardRepository: DashboardRepositoryProtocol {
    private let summaryRepository: SummaryRepositoryProtocol

    public init(summaryRepository: SummaryRepositoryProtocol) {
        self.summaryRepository = summaryRepository
    }

    public func fetchDashboardSummary() async throws -> Summary {
        try await summaryRepository.fetchSummary()
    }
}

@MainActor
public final class ReviewSessionRepository: ReviewSessionRepositoryProtocol {
    private let assignmentRepository: AssignmentRepositoryProtocol
    private let reviewRepository: ReviewRepositoryProtocol

    public init(
        assignmentRepository: AssignmentRepositoryProtocol,
        reviewRepository: ReviewRepositoryProtocol
    ) {
        self.assignmentRepository = assignmentRepository
        self.reviewRepository = reviewRepository
    }

    public func startReviewSession() async throws -> [AssignmentSnapshot] {
        let assignments = try await assignmentRepository.fetchAssignments(availableBefore: Date())
        return assignments
            .filter { !$0.hidden && $0.isAvailableForReview }
            .sorted { lhs, rhs in
                let lhsDate = lhs.availableAt ?? .distantPast
                let rhsDate = rhs.availableAt ?? .distantPast
                if lhsDate == rhsDate {
                    return lhs.id < rhs.id
                }
                return lhsDate < rhsDate
            }
    }

    public func submitReview(
        assignmentId: Int,
        incorrectMeaningAnswers: Int,
        incorrectReadingAnswers: Int
    ) async throws -> Review {
        try await reviewRepository.submitReview(
            assignmentId: assignmentId,
            incorrectMeaningAnswers: incorrectMeaningAnswers,
            incorrectReadingAnswers: incorrectReadingAnswers
        )
    }
}

@MainActor
public final class LessonSessionRepository: LessonSessionRepositoryProtocol {
    private let persistenceManager: PersistenceManager
    private let subjectRepository: SubjectRepositoryProtocol

    public init(
        persistenceManager: PersistenceManager,
        subjectRepository: SubjectRepositoryProtocol
    ) {
        self.persistenceManager = persistenceManager
        self.subjectRepository = subjectRepository
    }

    public func fetchLessonQueue() async throws -> [SubjectSnapshot] {
        let assignments = persistenceManager.fetchLessonAssignmentSnapshots(now: Date())

        var subjects: [SubjectSnapshot] = []
        subjects.reserveCapacity(assignments.count)

        for assignment in assignments {
            if let subject = try await subjectRepository.fetchSubject(id: assignment.subjectID) {
                subjects.append(subject)
            }
        }

        return subjects.sorted { lhs, rhs in
            if lhs.level == rhs.level {
                return lhs.slug < rhs.slug
            }
            return lhs.level < rhs.level
        }
    }
}

@MainActor
public final class SubjectDetailRepository: SubjectDetailRepositoryProtocol {
    private let subjectRepository: SubjectRepositoryProtocol

    public init(subjectRepository: SubjectRepositoryProtocol) {
        self.subjectRepository = subjectRepository
    }

    public func fetchSubjectDetail(id: Int) async throws -> SubjectSnapshot? {
        try await subjectRepository.fetchSubject(id: id)
    }
}

@MainActor
public final class ReviewHistoryRepository: ReviewHistoryRepositoryProtocol {
    private let api: WaniKaniAPI
    private let persistenceManager: PersistenceManager
    private let preferencesManager: PreferencesManager

    public init(
        api: WaniKaniAPI,
        persistenceManager: PersistenceManager,
        preferencesManager: PreferencesManager
    ) {
        self.api = api
        self.persistenceManager = persistenceManager
        self.preferencesManager = preferencesManager
    }

    public func syncReviewHistory() async throws {
        let updatedAfter = preferencesManager.lastReviewHistorySyncDate
        let reviews = try await api.getReviews(updatedAfter: updatedAfter)
        try persistenceManager.saveReviews(reviews)
        preferencesManager.lastReviewHistorySyncDate = Date()
    }

    public func fetchDailyReviewCounts(from: Date, to: Date) async throws -> [Date: Int] {
        persistenceManager.fetchDailyReviewCounts(from: from, to: to)
    }
}

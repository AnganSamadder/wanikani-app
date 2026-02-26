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
    private let persistenceManager: PersistenceManager

    public init(
        assignmentRepository: AssignmentRepositoryProtocol,
        reviewRepository: ReviewRepositoryProtocol,
        persistenceManager: PersistenceManager
    ) {
        self.assignmentRepository = assignmentRepository
        self.reviewRepository = reviewRepository
        self.persistenceManager = persistenceManager
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

    public func fetchPendingReviews() async throws -> [PendingReviewSnapshot] {
        persistenceManager.fetchPendingReviews()
    }

    public func upsertPendingReview(_ pending: PendingReviewSnapshot) async throws {
        try persistenceManager.upsertPendingReview(pending)
    }

    public func deletePendingReview(assignmentId: Int) async throws {
        try persistenceManager.deletePendingReview(assignmentID: assignmentId)
    }

    public func countHalfCompletions() async throws -> Int {
        persistenceManager.countHalfCompletions()
    }

    public func prunePendingReviews(validAssignmentIDs: Set<Int>) async throws {
        try persistenceManager.prunePendingReviews(validAssignmentIDs: validAssignmentIDs)
    }

    public func fetchStudyMaterial(subjectID: Int) async throws -> StudyMaterialSnapshot? {
        persistenceManager.fetchStudyMaterial(subjectID: subjectID)
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
        let subjectIDs = assignments.map(\.subjectID)
        let fetchedSubjects = try await subjectRepository.fetchSubjects(ids: subjectIDs)
        let subjectsByID = Dictionary(uniqueKeysWithValues: fetchedSubjects.map { ($0.id, $0) })
        let subjects = subjectIDs.compactMap { subjectsByID[$0] }

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
public final class SubjectRelationsRepository: SubjectRelationsRepositoryProtocol {
    private let subjectRepository: SubjectRepositoryProtocol

    public init(subjectRepository: SubjectRepositoryProtocol) {
        self.subjectRepository = subjectRepository
    }

    public func fetchSubjectDetails(ids: [Int]) async throws -> [SubjectSnapshot] {
        try await subjectRepository.fetchSubjects(ids: ids)
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

@MainActor
public final class PendingReviewRepository: PendingReviewRepositoryProtocol {
    private let persistenceManager: PersistenceManager

    public init(persistenceManager: PersistenceManager) {
        self.persistenceManager = persistenceManager
    }

    public func fetchPendingReviews() async throws -> [PendingReviewSnapshot] {
        persistenceManager.fetchPendingReviews()
    }

    public func upsertPendingReview(_ pending: PendingReviewSnapshot) async throws {
        try persistenceManager.upsertPendingReview(pending)
    }

    public func deletePendingReview(assignmentId: Int) async throws {
        try persistenceManager.deletePendingReview(assignmentID: assignmentId)
    }

    public func countHalfCompletions() async throws -> Int {
        persistenceManager.countHalfCompletions()
    }

    public func prunePendingReviews(validAssignmentIDs: Set<Int>) async throws {
        try persistenceManager.prunePendingReviews(validAssignmentIDs: validAssignmentIDs)
    }
}

@MainActor
public final class StudyMaterialRepository: StudyMaterialRepositoryProtocol {
    private let api: WaniKaniAPI
    private let persistenceManager: PersistenceManager

    public init(api: WaniKaniAPI, persistenceManager: PersistenceManager) {
        self.api = api
        self.persistenceManager = persistenceManager
    }

    public func syncStudyMaterials(subjectIDs: [Int]?) async throws {
        let materials = try await api.getStudyMaterials(subjectIDs: subjectIDs)
        try persistenceManager.saveStudyMaterials(materials)
    }

    public func fetchStudyMaterial(subjectID: Int) async throws -> StudyMaterialSnapshot? {
        persistenceManager.fetchStudyMaterial(subjectID: subjectID)
    }

    public func upsertStudyMaterial(
        subjectID: Int,
        meaningNote: String?,
        readingNote: String?,
        meaningSynonyms: [String]
    ) async throws -> StudyMaterialSnapshot {
        let saved = try await api.upsertStudyMaterial(
            subjectID: subjectID,
            meaningNote: meaningNote,
            readingNote: readingNote,
            meaningSynonyms: meaningSynonyms
        )
        let snapshot = StudyMaterialSnapshot(
            subjectID: saved.data.subjectID,
            meaningNote: saved.data.meaningNote,
            readingNote: saved.data.readingNote,
            meaningSynonyms: saved.data.meaningSynonyms,
            updatedAt: saved.dataUpdatedAt ?? Date()
        )
        try persistenceManager.saveStudyMaterialSnapshot(snapshot)
        return snapshot
    }
}

import Foundation

public protocol DashboardRepositoryProtocol: Sendable {
    func fetchDashboardSummary() async throws -> Summary
}

public protocol ReviewSessionRepositoryProtocol: Sendable {
    func startReviewSession() async throws -> [AssignmentSnapshot]
    func submitReview(
        assignmentId: Int,
        incorrectMeaningAnswers: Int,
        incorrectReadingAnswers: Int
    ) async throws -> Review
    func fetchPendingReviews() async throws -> [PendingReviewSnapshot]
    func upsertPendingReview(_ pending: PendingReviewSnapshot) async throws
    func deletePendingReview(assignmentId: Int) async throws
    func countHalfCompletions() async throws -> Int
    func prunePendingReviews(validAssignmentIDs: Set<Int>) async throws
    func fetchStudyMaterial(subjectID: Int) async throws -> StudyMaterialSnapshot?
    func fetchActiveQueueItems() async throws -> [ActiveQueueItemSnapshot]
    func upsertActiveQueueItem(_ item: ActiveQueueItemSnapshot) async throws
    func deleteActiveQueueItem(assignmentID: Int, questionType: String) async throws
    func clearActiveQueue() async throws
    func pruneActiveQueue(validAssignmentIDs: Set<Int>) async throws
}

public protocol LessonSessionRepositoryProtocol: Sendable {
    func fetchLessonQueue() async throws -> [SubjectSnapshot]
}

public protocol SubjectCatalogRepositoryProtocol: Sendable {
    func fetchSubjects(level: Int?) async throws -> [SubjectSnapshot]
}

public protocol SubjectDetailRepositoryProtocol: Sendable {
    func fetchSubjectDetail(id: Int) async throws -> SubjectSnapshot?
}

public protocol SubjectRelationsRepositoryProtocol: Sendable {
    func fetchSubjectDetails(ids: [Int]) async throws -> [SubjectSnapshot]
}

public protocol SettingsRepositoryProtocol: Sendable {
    func loadAPIKey() async throws -> String?
    func saveAPIKey(_ key: String) async throws
}

public protocol SearchRepositoryProtocol: Sendable {
    func searchSubjects(query: String) async throws -> [SubjectSnapshot]
}

public protocol ExtraStudyRepositoryProtocol: Sendable {
    func fetchRecentlyMissed() async throws -> [SubjectSnapshot]
}

public protocol CommunityRepositoryProtocol: Sendable {
    func fetchCategories() async throws -> [CommunityCategory]
    func fetchTopics(categoryId: Int?) async throws -> [CommunityTopic]
    func searchTopics(query: String) async throws -> [CommunityTopic]
    func fetchTopic(id: Int) async throws -> CommunityTopicDetail
    func createTopic(title: String, raw: String, categoryId: Int?) async throws -> CommunityTopic
    func createReply(topicId: Int, raw: String) async throws
    func editPost(postId: Int, raw: String) async throws
    func likePost(postId: Int) async throws
    func bookmarkPost(postId: Int) async throws
}

public protocol ReviewHistoryRepositoryProtocol: Sendable {
    func syncReviewHistory() async throws
    func fetchDailyReviewCounts(from: Date, to: Date) async throws -> [Date: Int]
}

public protocol PendingReviewRepositoryProtocol: Sendable {
    func fetchPendingReviews() async throws -> [PendingReviewSnapshot]
    func upsertPendingReview(_ pending: PendingReviewSnapshot) async throws
    func deletePendingReview(assignmentId: Int) async throws
    func countHalfCompletions() async throws -> Int
    func prunePendingReviews(validAssignmentIDs: Set<Int>) async throws
}

public protocol StudyMaterialRepositoryProtocol: Sendable {
    func syncStudyMaterials(subjectIDs: [Int]?) async throws
    func fetchStudyMaterial(subjectID: Int) async throws -> StudyMaterialSnapshot?
    func upsertStudyMaterial(
        subjectID: Int,
        meaningNote: String?,
        readingNote: String?,
        meaningSynonyms: [String]
    ) async throws -> StudyMaterialSnapshot
}

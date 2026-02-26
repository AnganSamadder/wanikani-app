import Foundation
import SwiftUI
import WaniKaniCore

@MainActor
final class ReviewSessionViewModel: ObservableObject {

    // MARK: - Types

    enum State: Equatable {
        case idle, loading, ready, empty, complete, failed(String)
    }

    enum QueuePolicy {
        case normal
        case finishPendingOnly
    }

    enum ReviewPhase: Equatable {
        case answering
        case feedback
    }

    enum QuestionType: String {
        case meaning = "Meaning"
        case reading = "Reading"
    }

    struct Prompt: Equatable {
        let subjectCharacters: String
        let subjectMeaning: String
        let questionType: QuestionType
        let subjectType: String

        var title: String { "\(subjectType.capitalized) \(questionType.rawValue)" }
        var placeholder: String { questionType == .meaning ? "Enter meaning" : "Enter reading" }
    }

    struct ReviewAttemptRecord: Identifiable {
        let id = UUID()
        let characters: String
        let subjectMeaning: String
        let questionType: QuestionType
        let userAnswer: String
        let wasCorrect: Bool
        let timestamp: Date
    }

    private struct QueueItem {
        let assignment: AssignmentSnapshot
        let subject: SubjectSnapshot
        let questionType: QuestionType
    }

    private struct SessionItem {
        let assignmentID: Int
        let subjectID: Int
        let subjectType: String
        var incorrectMeaningAnswers: Int
        var incorrectReadingAnswers: Int
        var meaningCorrect: Bool
        var readingCorrect: Bool
        let hasReadings: Bool

        var isComplete: Bool { meaningCorrect && (readingCorrect || !hasReadings) }
    }

    private struct UndoCheckpoint {
        let previousPrompt: Prompt
        let previousSessionItem: SessionItem
        let restoredQueueItem: QueueItem
        let previousAttemptCount: Int
        let wasComplete: Bool
        let didRequeue: Bool
    }

    // MARK: - Published State

    @Published private(set) var state: State = .idle
    @Published private(set) var prompt: Prompt?
    @Published private(set) var phase: ReviewPhase = .answering
    @Published private(set) var canUndo: Bool = false
    @Published private(set) var attemptHistory: [ReviewAttemptRecord] = []
    @Published private(set) var navigateToTab: AppRoute? = nil
    @Published private(set) var isSubmitting = false
    @Published private(set) var lastAnswerCorrect: Bool? = nil
    @Published private(set) var currentSubject: SubjectSnapshot?
    @Published private(set) var pendingHalfCompletionCount: Int = 0
    @Published var userAnswer = ""
    @Published var timerModeEnabled: Bool = false

    // MARK: - Queue

    private var unseenQueue: [QueueItem] = []
    private var activeQueue: [QueueItem] = []
    private var currentItem: QueueItem?
    private var sessionItems: [Int: SessionItem] = [:]
    private var pendingCommit: SessionItem? = nil
    private var undoCheckpoint: UndoCheckpoint? = nil
    private var loadTask: Task<Void, Never>? = nil

    // MARK: - Dependencies

    private let reviewSessionRepository: ReviewSessionRepositoryProtocol
    private let subjectDetailRepository: SubjectDetailRepositoryProtocol
    private let subjectRelationsRepository: SubjectRelationsRepositoryProtocol
    private let studyMaterialRepository: StudyMaterialRepositoryProtocol

    init(
        reviewSessionRepository: ReviewSessionRepositoryProtocol,
        subjectDetailRepository: SubjectDetailRepositoryProtocol,
        subjectRelationsRepository: SubjectRelationsRepositoryProtocol,
        studyMaterialRepository: StudyMaterialRepositoryProtocol
    ) {
        self.reviewSessionRepository = reviewSessionRepository
        self.subjectDetailRepository = subjectDetailRepository
        self.subjectRelationsRepository = subjectRelationsRepository
        self.studyMaterialRepository = studyMaterialRepository
    }

    // MARK: - Computed

    var remainingCount: Int {
        unseenQueue.count + activeQueue.count + (currentItem == nil ? 0 : 1)
    }

    var detailsAvailable: Bool { phase == .feedback }

    // MARK: - Load

    func load(policy: QueuePolicy = .normal) async {
        if let loadTask {
            await loadTask.value
            return
        }

        let task = Task { [self] in
            await performLoad(policy: policy)
        }
        loadTask = task
        await task.value
        loadTask = nil
    }

    func prefetchIfNeeded() async {
        guard state == .idle else { return }
        await load()
    }

    private func performLoad(policy: QueuePolicy) async {
        state = .loading
        phase = .answering
        userAnswer = ""
        attemptHistory = []
        canUndo = false
        pendingCommit = nil
        undoCheckpoint = nil
        navigateToTab = nil
        currentItem = nil
        currentSubject = nil
        prompt = nil

        do {
            let assignments = try await reviewSessionRepository.startReviewSession()
            if assignments.isEmpty {
                state = .empty
                pendingHalfCompletionCount = 0
                return
            }

            let assignmentIDs = Set(assignments.map(\.id))
            try? await reviewSessionRepository.prunePendingReviews(validAssignmentIDs: assignmentIDs)

            var pendingByAssignment = Dictionary(
                uniqueKeysWithValues: try await reviewSessionRepository
                    .fetchPendingReviews()
                    .map { ($0.assignmentID, $0) }
            )

            // Recover completed-but-not-submitted answers from prior app exit.
            for pending in pendingByAssignment.values
            where pending.hasReadings && pending.meaningCompleted && pending.readingCompleted {
                do {
                    _ = try await reviewSessionRepository.submitReview(
                        assignmentId: pending.assignmentID,
                        incorrectMeaningAnswers: pending.incorrectMeaningAnswers,
                        incorrectReadingAnswers: pending.incorrectReadingAnswers
                    )
                    try? await reviewSessionRepository.deletePendingReview(assignmentId: pending.assignmentID)
                    pendingByAssignment.removeValue(forKey: pending.assignmentID)
                } catch {
                    // Keep persisted pending state for next retry.
                }
            }

            try? await studyMaterialRepository.syncStudyMaterials(subjectIDs: assignments.map(\.subjectID))
            let subjectsByID = try await fetchSubjectsByID(for: assignments)

            var loadedItems: [QueueItem] = []
            var loadedSessions: [Int: SessionItem] = [:]

            for assignment in assignments {
                let subject: SubjectSnapshot
                if let batchedSubject = subjectsByID[assignment.subjectID] {
                    subject = batchedSubject
                } else if let fallbackSubject = try await subjectDetailRepository.fetchSubjectDetail(id: assignment.subjectID) {
                    subject = fallbackSubject
                } else {
                    continue
                }

                let pending = pendingByAssignment[assignment.id]
                let session = SessionItem(
                    assignmentID: assignment.id,
                    subjectID: assignment.subjectID,
                    subjectType: assignment.subjectType.rawValue,
                    incorrectMeaningAnswers: pending?.incorrectMeaningAnswers ?? 0,
                    incorrectReadingAnswers: pending?.incorrectReadingAnswers ?? 0,
                    meaningCorrect: pending?.meaningCompleted ?? false,
                    readingCorrect: pending?.readingCompleted ?? false,
                    hasReadings: subject.hasReadings
                )
                loadedSessions[assignment.id] = session

                switch policy {
                case .normal:
                    if !session.meaningCorrect {
                        loadedItems.append(QueueItem(assignment: assignment, subject: subject, questionType: .meaning))
                    }
                    if session.hasReadings && !session.readingCorrect {
                        loadedItems.append(QueueItem(assignment: assignment, subject: subject, questionType: .reading))
                    }
                case .finishPendingOnly:
                    guard session.hasReadings, session.meaningCorrect != session.readingCorrect else { continue }
                    let missingType: QuestionType = session.meaningCorrect ? .reading : .meaning
                    loadedItems.append(QueueItem(assignment: assignment, subject: subject, questionType: missingType))
                }
            }

            let shuffled = loadedItems.shuffled()
            if policy == .finishPendingOnly {
                activeQueue = shuffled
                unseenQueue = []
            } else {
                unseenQueue = shuffled
                activeQueue = []
            }

            sessionItems = loadedSessions
            await refreshPendingHalfCompletionCount()
            advanceToNextItem()
            state = currentItem == nil ? .empty : .ready
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    // MARK: - Submit Answer

    func submitCurrentAnswer() async {
        guard state == .ready,
              let activeItem = currentItem,
              !userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let answer = userAnswer
        guard var sessionItem = sessionItems[activeItem.assignment.id] else {
            state = .failed("Missing session state")
            return
        }
        let previousSessionItem = sessionItem
        let previousAttemptCount = attemptHistory.count

        let isCorrect: Bool
        switch activeItem.questionType {
        case .meaning:
            let synonyms = (try? await studyMaterialRepository.fetchStudyMaterial(subjectID: activeItem.subject.id))?.meaningSynonyms ?? []
            isCorrect = AnswerChecker.checkMeaning(answer, for: activeItem.subject, userSynonyms: synonyms)
        case .reading:
            isCorrect = AnswerChecker.checkReading(answer, for: activeItem.subject)
        }

        attemptHistory.append(ReviewAttemptRecord(
            characters: activeItem.subject.characters ?? activeItem.subject.slug,
            subjectMeaning: activeItem.subject.primaryMeaning ?? activeItem.subject.slug,
            questionType: activeItem.questionType,
            userAnswer: answer,
            wasCorrect: isCorrect,
            timestamp: Date()
        ))

        if isCorrect {
            switch activeItem.questionType {
            case .meaning: sessionItem.meaningCorrect = true
            case .reading: sessionItem.readingCorrect = true
            }
        } else {
            switch activeItem.questionType {
            case .meaning: sessionItem.incorrectMeaningAnswers += 1
            case .reading: sessionItem.incorrectReadingAnswers += 1
            }
            activeQueue.append(activeItem)
        }

        sessionItems[activeItem.assignment.id] = sessionItem
        let wasComplete = sessionItem.isComplete

        if sessionItem.hasReadings {
            try? await reviewSessionRepository.upsertPendingReview(
                PendingReviewSnapshot(
                    assignmentID: sessionItem.assignmentID,
                    subjectID: sessionItem.subjectID,
                    subjectType: sessionItem.subjectType,
                    hasReadings: true,
                    meaningCompleted: sessionItem.meaningCorrect,
                    readingCompleted: sessionItem.readingCorrect,
                    incorrectMeaningAnswers: sessionItem.incorrectMeaningAnswers,
                    incorrectReadingAnswers: sessionItem.incorrectReadingAnswers,
                    updatedAt: Date()
                )
            )
        }

        if wasComplete {
            pendingCommit = sessionItem
            sessionItems.removeValue(forKey: sessionItem.assignmentID)
        }

        if let existingPrompt = prompt {
            undoCheckpoint = UndoCheckpoint(
                previousPrompt: existingPrompt,
                previousSessionItem: previousSessionItem,
                restoredQueueItem: activeItem,
                previousAttemptCount: previousAttemptCount,
                wasComplete: wasComplete,
                didRequeue: !isCorrect
            )
        } else {
            undoCheckpoint = nil
        }

        await refreshPendingHalfCompletionCount()
        lastAnswerCorrect = isCorrect
        phase = .feedback
        canUndo = true
    }

    // MARK: - Next

    func next() async {
        if let commit = pendingCommit {
            do {
                _ = try await reviewSessionRepository.submitReview(
                    assignmentId: commit.assignmentID,
                    incorrectMeaningAnswers: commit.incorrectMeaningAnswers,
                    incorrectReadingAnswers: commit.incorrectReadingAnswers
                )
                if commit.hasReadings {
                    try? await reviewSessionRepository.deletePendingReview(assignmentId: commit.assignmentID)
                }
            } catch {
                // Keep cached pending progress for retry on next session.
            }
            pendingCommit = nil
        }

        undoCheckpoint = nil
        canUndo = false
        await refreshPendingHalfCompletionCount()

        let queuesEmpty = activeQueue.isEmpty && unseenQueue.isEmpty && pendingCommit == nil
        if timerModeEnabled && queuesEmpty && pendingHalfCompletionCount == 0 {
            navigateToTab = .dashboard
            return
        }

        advanceToNextItem()
        userAnswer = ""
        lastAnswerCorrect = nil
        phase = .answering

        if currentItem == nil {
            state = .complete
        }
    }

    // MARK: - Undo

    func undo() async {
        guard canUndo, let checkpoint = undoCheckpoint else { return }

        attemptHistory = Array(attemptHistory.prefix(checkpoint.previousAttemptCount))

        if checkpoint.didRequeue,
           let lastIdx = activeQueue.indices.last,
           activeQueue[lastIdx].assignment.id == checkpoint.restoredQueueItem.assignment.id,
           activeQueue[lastIdx].questionType == checkpoint.restoredQueueItem.questionType {
            activeQueue.removeLast()
        }

        if checkpoint.wasComplete {
            pendingCommit = nil
        }

        sessionItems[checkpoint.previousSessionItem.assignmentID] = checkpoint.previousSessionItem

        if checkpoint.previousSessionItem.hasReadings {
            let hasAnyProgress =
                checkpoint.previousSessionItem.meaningCorrect ||
                checkpoint.previousSessionItem.readingCorrect ||
                checkpoint.previousSessionItem.incorrectMeaningAnswers > 0 ||
                checkpoint.previousSessionItem.incorrectReadingAnswers > 0

            if hasAnyProgress {
                try? await reviewSessionRepository.upsertPendingReview(
                    PendingReviewSnapshot(
                        assignmentID: checkpoint.previousSessionItem.assignmentID,
                        subjectID: checkpoint.previousSessionItem.subjectID,
                        subjectType: checkpoint.previousSessionItem.subjectType,
                        hasReadings: true,
                        meaningCompleted: checkpoint.previousSessionItem.meaningCorrect,
                        readingCompleted: checkpoint.previousSessionItem.readingCorrect,
                        incorrectMeaningAnswers: checkpoint.previousSessionItem.incorrectMeaningAnswers,
                        incorrectReadingAnswers: checkpoint.previousSessionItem.incorrectReadingAnswers,
                        updatedAt: Date()
                    )
                )
            } else {
                try? await reviewSessionRepository.deletePendingReview(assignmentId: checkpoint.previousSessionItem.assignmentID)
            }
        }

        currentItem = checkpoint.restoredQueueItem
        currentSubject = checkpoint.restoredQueueItem.subject
        prompt = checkpoint.previousPrompt
        userAnswer = ""
        lastAnswerCorrect = nil
        undoCheckpoint = nil
        canUndo = false
        phase = .answering
        await refreshPendingHalfCompletionCount()
    }

    // MARK: - Finish-pending mode

    func setTimerModeEnabled(_ enabled: Bool) async {
        timerModeEnabled = enabled
        await load(policy: enabled ? .finishPendingOnly : .normal)
    }

    // MARK: - Subject details dependencies

    func fetchRelatedSubjects(ids: [Int]) async -> [SubjectSnapshot] {
        guard !ids.isEmpty else { return [] }
        return (try? await subjectRelationsRepository.fetchSubjectDetails(ids: ids)) ?? []
    }

    func fetchSubjectDetail(id: Int) async -> SubjectSnapshot? {
        try? await subjectDetailRepository.fetchSubjectDetail(id: id)
    }

    func fetchStudyMaterial(subjectID: Int) async -> StudyMaterialSnapshot? {
        if (try? await studyMaterialRepository.fetchStudyMaterial(subjectID: subjectID)) == nil {
            try? await studyMaterialRepository.syncStudyMaterials(subjectIDs: [subjectID])
        }
        return try? await studyMaterialRepository.fetchStudyMaterial(subjectID: subjectID)
    }

    func saveStudyMaterial(
        subjectID: Int,
        meaningNote: String?,
        readingNote: String?,
        meaningSynonyms: [String]
    ) async -> StudyMaterialSnapshot? {
        let snapshot = try? await studyMaterialRepository.upsertStudyMaterial(
            subjectID: subjectID,
            meaningNote: meaningNote,
            readingNote: readingNote,
            meaningSynonyms: meaningSynonyms
        )
        return snapshot
    }

    // MARK: - Private helpers

    private func refreshPendingHalfCompletionCount() async {
        pendingHalfCompletionCount = (try? await reviewSessionRepository.countHalfCompletions()) ?? 0
    }

    private func fetchSubjectsByID(for assignments: [AssignmentSnapshot]) async throws -> [Int: SubjectSnapshot] {
        let subjectIDs = uniqueInOrder(assignments.map(\.subjectID))
        guard !subjectIDs.isEmpty else { return [:] }
        let subjects = try await subjectRelationsRepository.fetchSubjectDetails(ids: subjectIDs)
        return Dictionary(uniqueKeysWithValues: subjects.map { ($0.id, $0) })
    }

    private func uniqueInOrder(_ ids: [Int]) -> [Int] {
        var seen: Set<Int> = []
        var ordered: [Int] = []
        ordered.reserveCapacity(ids.count)

        for id in ids where seen.insert(id).inserted {
            ordered.append(id)
        }
        return ordered
    }

    private func advanceToNextItem() {
        currentItem = nil
        prompt = nil
        currentSubject = nil

        // Prioritize unseen prompts so incorrect answers are revisited later
        // instead of bouncing immediately to the same prompt.
        if !unseenQueue.isEmpty {
            let next = unseenQueue.removeFirst()
            setCurrentItem(next)
        } else if !activeQueue.isEmpty {
            let next = activeQueue.removeFirst()
            setCurrentItem(next)
        }
    }

    private func setCurrentItem(_ item: QueueItem) {
        currentItem = item
        currentSubject = item.subject
        prompt = Prompt(
            subjectCharacters: item.subject.characters ?? item.subject.slug,
            subjectMeaning: item.subject.primaryMeaning ?? item.subject.slug,
            questionType: item.questionType,
            subjectType: item.subject.object
        )
    }
}

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
        let readyAtStep: Int   // Int.min = always ready (unseen); stepCount+TTL = delayed
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
        let previousStepCount: Int
        let addedActiveQueueType: QuestionType?
        let activeQueueTypeMovedFromUnseen: Bool
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
    private var stepCount: Int = 0

    // MARK: - Dependencies

    private let reviewSessionRepository: ReviewSessionRepositoryProtocol
    private let subjectDetailRepository: SubjectDetailRepositoryProtocol
    private let subjectRelationsRepository: SubjectRelationsRepositoryProtocol
    private let studyMaterialRepository: StudyMaterialRepositoryProtocol
    private let reviewTTL: Int

    init(
        reviewSessionRepository: ReviewSessionRepositoryProtocol,
        subjectDetailRepository: SubjectDetailRepositoryProtocol,
        subjectRelationsRepository: SubjectRelationsRepositoryProtocol,
        studyMaterialRepository: StudyMaterialRepositoryProtocol,
        reviewTTL: Int = 5
    ) {
        self.reviewSessionRepository = reviewSessionRepository
        self.subjectDetailRepository = subjectDetailRepository
        self.subjectRelationsRepository = subjectRelationsRepository
        self.studyMaterialRepository = studyMaterialRepository
        self.reviewTTL = reviewTTL
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
        stepCount = 0

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

                if policy == .normal {
                    if !session.meaningCorrect {
                        loadedItems.append(QueueItem(assignment: assignment, subject: subject,
                                                     questionType: .meaning, readyAtStep: Int.min))
                    }
                    if session.hasReadings && !session.readingCorrect {
                        loadedItems.append(QueueItem(assignment: assignment, subject: subject,
                                                     questionType: .reading, readyAtStep: Int.min))
                    }
                }
            }

            sessionItems = loadedSessions

            // Load persisted active queue items
            let persistedCompanions = (try? await reviewSessionRepository.fetchActiveQueueItems()) ?? []
            let validAssignmentIDs = Set(assignments.map(\.id))
            let assignmentsByID = Dictionary(uniqueKeysWithValues: assignments.map { ($0.id, $0) })

            if policy == .finishPendingOnly {
                // Fast-forward: serve all companion items immediately, no unseen queue
                unseenQueue = []
                activeQueue = []
                for companion in persistedCompanions where validAssignmentIDs.contains(companion.assignmentID) {
                    guard let subject = subjectsByID[companion.subjectID],
                          let assignment = assignmentsByID[companion.assignmentID] else { continue }
                    let questionType = QuestionType(rawValue: companion.questionType) ?? .meaning
                    let session = loadedSessions[companion.assignmentID]
                    let alreadyDone: Bool
                    switch questionType {
                    case .meaning: alreadyDone = session?.meaningCorrect ?? false
                    case .reading: alreadyDone = session?.readingCorrect ?? false
                    }
                    guard !alreadyDone else { continue }
                    activeQueue.append(QueueItem(assignment: assignment, subject: subject,
                                                 questionType: questionType, readyAtStep: 0))
                }
            } else {
                unseenQueue = loadedItems.shuffled()
                activeQueue = []
                // Append companion queue items that aren't already in unseenQueue
                for companion in persistedCompanions where validAssignmentIDs.contains(companion.assignmentID) {
                    guard let subject = subjectsByID[companion.subjectID],
                          let assignment = assignmentsByID[companion.assignmentID] else { continue }
                    let questionType = QuestionType(rawValue: companion.questionType) ?? .meaning
                    let session = loadedSessions[companion.assignmentID]
                    let alreadyDone: Bool
                    switch questionType {
                    case .meaning: alreadyDone = session?.meaningCorrect ?? false
                    case .reading: alreadyDone = session?.readingCorrect ?? false
                    }
                    guard !alreadyDone else { continue }
                    // Remove from unseenQueue if present so the TTL delay applies
                    if let unseenIdx = unseenQueue.firstIndex(where: {
                        $0.assignment.id == companion.assignmentID && $0.questionType == questionType
                    }) {
                        unseenQueue.remove(at: unseenIdx)
                    }
                    // Avoid duplicates in activeQueue
                    let alreadyActive = activeQueue.contains(where: {
                        $0.assignment.id == companion.assignmentID && $0.questionType == questionType
                    })
                    guard !alreadyActive else { continue }
                    activeQueue.append(QueueItem(assignment: assignment, subject: subject,
                                                 questionType: questionType, readyAtStep: reviewTTL))
                }
            }

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

        // Track step count before incrementing (for undo restore)
        let previousStepCount = stepCount
        if !timerModeEnabled {
            stepCount += 1
        }

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
            if !timerModeEnabled {
                // Re-queue with TTL so it comes back after reviewTTL more answers
                activeQueue.append(QueueItem(
                    assignment: activeItem.assignment,
                    subject: activeItem.subject,
                    questionType: activeItem.questionType,
                    readyAtStep: stepCount + reviewTTL
                ))
            }
            // Fast-forward: wrong answer removed permanently (item was already popped)
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

        // Auto-add companion side with TTL on correct answer (normal mode only)
        var addedActiveQueueType: QuestionType? = nil
        var activeQueueTypeMovedFromUnseen: Bool = false
        if isCorrect && !timerModeEnabled {
            if let updatedSession = sessionItems[activeItem.assignment.id] {
                let companionType: QuestionType = activeItem.questionType == .meaning ? .reading : .meaning
                let companionNeeded: Bool
                switch companionType {
                case .reading: companionNeeded = updatedSession.hasReadings && !updatedSession.readingCorrect
                case .meaning: companionNeeded = !updatedSession.meaningCorrect
                }
                let alreadyInActive = activeQueue.contains(where: {
                    $0.assignment.id == activeItem.assignment.id && $0.questionType == companionType
                })
                if companionNeeded && !alreadyInActive {
                    // Move from unseenQueue to activeQueue if present so TTL delay applies
                    if let unseenIdx = unseenQueue.firstIndex(where: {
                        $0.assignment.id == activeItem.assignment.id && $0.questionType == companionType
                    }) {
                        unseenQueue.remove(at: unseenIdx)
                        activeQueueTypeMovedFromUnseen = true
                    }
                    activeQueue.append(QueueItem(
                        assignment: activeItem.assignment,
                        subject: activeItem.subject,
                        questionType: companionType,
                        readyAtStep: stepCount + reviewTTL
                    ))
                    addedActiveQueueType = companionType
                    try? await reviewSessionRepository.upsertActiveQueueItem(
                        ActiveQueueItemSnapshot(
                            assignmentID: activeItem.assignment.id,
                            subjectID: activeItem.assignment.subjectID,
                            subjectType: activeItem.assignment.subjectType.rawValue,
                            questionType: companionType.rawValue
                        )
                    )
                }
            }
        }

        // When a side is answered correctly, remove its active queue persistence entry
        if isCorrect {
            try? await reviewSessionRepository.deleteActiveQueueItem(
                assignmentID: activeItem.assignment.id,
                questionType: activeItem.questionType.rawValue
            )
        }

        if let existingPrompt = prompt {
            undoCheckpoint = UndoCheckpoint(
                previousPrompt: existingPrompt,
                previousSessionItem: previousSessionItem,
                restoredQueueItem: activeItem,
                previousAttemptCount: previousAttemptCount,
                wasComplete: wasComplete,
                didRequeue: !isCorrect && !timerModeEnabled,
                previousStepCount: previousStepCount,
                addedActiveQueueType: addedActiveQueueType,
                activeQueueTypeMovedFromUnseen: activeQueueTypeMovedFromUnseen
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

        // Restore step count
        stepCount = checkpoint.previousStepCount

        if checkpoint.didRequeue,
           let lastIdx = activeQueue.indices.last,
           activeQueue[lastIdx].assignment.id == checkpoint.restoredQueueItem.assignment.id,
           activeQueue[lastIdx].questionType == checkpoint.restoredQueueItem.questionType {
            activeQueue.removeLast()
        }

        // Undo active queue addition (companion side added on correct answer)
        if let addedType = checkpoint.addedActiveQueueType {
            if let idx = activeQueue.firstIndex(where: {
                $0.assignment.id == checkpoint.restoredQueueItem.assignment.id &&
                $0.questionType == addedType
            }) {
                activeQueue.remove(at: idx)
            }
            // Restore to unseenQueue if it was moved from there
            if checkpoint.activeQueueTypeMovedFromUnseen {
                unseenQueue.append(QueueItem(
                    assignment: checkpoint.restoredQueueItem.assignment,
                    subject: checkpoint.restoredQueueItem.subject,
                    questionType: addedType,
                    readyAtStep: Int.min
                ))
            }
            try? await reviewSessionRepository.deleteActiveQueueItem(
                assignmentID: checkpoint.restoredQueueItem.assignment.id,
                questionType: addedType.rawValue
            )
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

        // Restore the companion queue entry for the item being undone (if it was deleted)
        // (it was answered correctly and its companion persistence entry was deleted)
        // The companion tracking is the responsibility of the new answer, not the undo.

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

        if timerModeEnabled {
            // Fast-forward: serve all active items regardless of readyAtStep
            guard !activeQueue.isEmpty else { return }
            let next = activeQueue.removeFirst()
            setCurrentItem(next)
            return
        }

        // Count ready active items (activeQueue is ordered by ascending readyAtStep)
        let readyCount = activeQueue.prefix(while: { $0.readyAtStep <= stepCount }).count
        let hasUnseen = !unseenQueue.isEmpty
        let hasReady = readyCount > 0

        switch (hasUnseen, hasReady) {
        case (true, true):
            if Bool.random() {
                let next = unseenQueue.removeFirst()
                setCurrentItem(next)
            } else {
                let idx = Int.random(in: 0..<readyCount)
                let next = activeQueue.remove(at: idx)
                setCurrentItem(next)
            }
        case (true, false):
            let next = unseenQueue.removeFirst()
            setCurrentItem(next)
        case (false, true):
            let idx = Int.random(in: 0..<readyCount)
            let next = activeQueue.remove(at: idx)
            setCurrentItem(next)
        case (false, false):
            break
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

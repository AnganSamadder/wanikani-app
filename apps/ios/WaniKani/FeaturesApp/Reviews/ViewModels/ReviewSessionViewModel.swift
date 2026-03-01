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

        var opposite: QuestionType {
            self == .meaning ? .reading : .meaning
        }
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

    /// Stable deduplication key for the active map.
    struct PromptKey: Hashable {
        let assignmentID: Int
        let questionType: QuestionType
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
        /// Keys inserted into the active map (both sides on wrong answer).
        let addedActiveKeys: [PromptKey]
        /// Items removed from unseenQueue (restored on undo).
        let removedUnseenItems: [QueueItem]
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
    /// O(1) lookup/dedup/TTL-refresh map keyed by PromptKey.
    private var activeMap: [PromptKey: QueueItem] = [:]
    /// Wake buckets: keys that become ready at a given stepCount value.
    private var wakeBuckets: [Int: Set<PromptKey>] = [:]
    /// Items where readyAtStep <= stepCount — eligible for immediate selection.
    private var readyPool: [PromptKey] = []
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
    let reviewTTL: Int

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
        unseenQueue.count + activeMap.count + (currentItem == nil ? 0 : 1)
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
        activeMap = [:]
        wakeBuckets = [:]
        readyPool = []

        do {
            let assignments = try await reviewSessionRepository.startReviewSession()
            if assignments.isEmpty {
                state = .empty
                pendingHalfCompletionCount = 0
                return
            }

            let assignmentIDs = Set(assignments.map(\.id))
            try? await reviewSessionRepository.prunePendingReviews(validAssignmentIDs: assignmentIDs)
            try? await reviewSessionRepository.pruneActiveQueue(validAssignmentIDs: assignmentIDs)

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

            let persistedActive = (try? await reviewSessionRepository.fetchActiveQueueItems()) ?? []
            let assignmentsByID = Dictionary(uniqueKeysWithValues: assignments.map { ($0.id, $0) })

            if policy == .finishPendingOnly {
                // Fast-forward: serve all active items immediately, no unseen queue.
                unseenQueue = []
                for active in persistedActive where assignmentIDs.contains(active.assignmentID) {
                    guard let subject = subjectsByID[active.subjectID],
                          let assignment = assignmentsByID[active.assignmentID] else { continue }
                    let questionType = QuestionType(rawValue: active.questionType) ?? .meaning
                    let session = loadedSessions[active.assignmentID]
                    let alreadyDone: Bool
                    switch questionType {
                    case .meaning: alreadyDone = session?.meaningCorrect ?? false
                    case .reading: alreadyDone = session?.readingCorrect ?? false
                    }
                    guard !alreadyDone else { continue }
                    // readyAtStep = 0 with stepCount = 0: goes directly into readyPool.
                    insertOrRefreshActive(QueueItem(assignment: assignment, subject: subject,
                                                    questionType: questionType, readyAtStep: 0))
                }
            } else {
                unseenQueue = loadedItems.shuffled()
                // Load persisted active items with TTL reset to reviewTTL from step 0.
                for active in persistedActive where assignmentIDs.contains(active.assignmentID) {
                    guard let subject = subjectsByID[active.subjectID],
                          let assignment = assignmentsByID[active.assignmentID] else { continue }
                    let questionType = QuestionType(rawValue: active.questionType) ?? .meaning
                    let session = loadedSessions[active.assignmentID]
                    let alreadyDone: Bool
                    switch questionType {
                    case .meaning: alreadyDone = session?.meaningCorrect ?? false
                    case .reading: alreadyDone = session?.readingCorrect ?? false
                    }
                    guard !alreadyDone else { continue }
                    // Remove from unseenQueue if present so TTL delay applies.
                    unseenQueue.removeAll {
                        $0.assignment.id == active.assignmentID && $0.questionType == questionType
                    }
                    insertOrRefreshActive(QueueItem(assignment: assignment, subject: subject,
                                                    questionType: questionType,
                                                    readyAtStep: reviewTTL))
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

        // Capture stepCount before any modification (for undo restore).
        let previousStepCount = stepCount

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

        // Wrong answer in normal mode: enqueue both sides with TTL.
        var addedActiveKeys: [PromptKey] = []
        var removedUnseenItems: [QueueItem] = []
        if !isCorrect && !timerModeEnabled {
            // Capture unseen items for this assignment before removing them (for undo).
            removedUnseenItems = unseenQueue.filter { $0.assignment.id == activeItem.assignment.id }
            unseenQueue.removeAll { $0.assignment.id == activeItem.assignment.id }

            let sides: [QuestionType] = activeItem.subject.hasReadings
                ? [activeItem.questionType, activeItem.questionType.opposite]
                : [activeItem.questionType]

            for side in sides {
                let key = PromptKey(assignmentID: activeItem.assignment.id, questionType: side)
                addedActiveKeys.append(key)
                let queued = QueueItem(
                    assignment: activeItem.assignment,
                    subject: activeItem.subject,
                    questionType: side,
                    readyAtStep: stepCount + reviewTTL
                )
                insertOrRefreshActive(queued)
                Task { [weak self] in
                    try? await self?.reviewSessionRepository.upsertActiveQueueItem(
                        ActiveQueueItemSnapshot(
                            assignmentID: activeItem.assignment.id,
                            subjectID: activeItem.assignment.subjectID,
                            subjectType: activeItem.assignment.subjectType.rawValue,
                            questionType: side.rawValue
                        )
                    )
                }
            }
        }

        // Correct answer: delete the active queue persistence entry for this side.
        if isCorrect {
            Task { [weak self] in
                try? await self?.reviewSessionRepository.deleteActiveQueueItem(
                    assignmentID: activeItem.assignment.id,
                    questionType: activeItem.questionType.rawValue
                )
            }
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
                addedActiveKeys: addedActiveKeys,
                removedUnseenItems: removedUnseenItems
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

        // Fast-forward: navigate to dashboard when all active items and half-completions are gone.
        if timerModeEnabled {
            let queuesEmpty = activeMap.isEmpty && pendingHalfCompletionCount == 0
            if queuesEmpty {
                navigateToTab = .dashboard
                return
            }
        } else {
            // Normal mode: advance one step and drain the corresponding wake bucket.
            advanceStep()
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

        // Restore step count.
        stepCount = checkpoint.previousStepCount

        // Remove all keys that were added to active by this answer (wrong-answer path).
        for key in checkpoint.addedActiveKeys {
            if let item = activeMap.removeValue(forKey: key) {
                wakeBuckets[item.readyAtStep]?.remove(key)
                readyPool.removeAll { $0 == key }
            }
            Task { [weak self] in
                try? await self?.reviewSessionRepository.deleteActiveQueueItem(
                    assignmentID: key.assignmentID,
                    questionType: key.questionType.rawValue
                )
            }
        }

        // Restore items that were removed from unseenQueue.
        for item in checkpoint.removedUnseenItems {
            unseenQueue.append(item)
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

    /// Insert or refresh an item in the active map with O(1) dedup and TTL-refresh.
    private func insertOrRefreshActive(_ item: QueueItem) {
        let key = PromptKey(assignmentID: item.assignment.id, questionType: item.questionType)

        // Remove from old placement if already present.
        if let existing = activeMap[key] {
            wakeBuckets[existing.readyAtStep]?.remove(key)
            readyPool.removeAll { $0 == key }
        }

        activeMap[key] = item

        if item.readyAtStep <= stepCount {
            readyPool.append(key)
        } else {
            wakeBuckets[item.readyAtStep, default: []].insert(key)
        }
    }

    /// Increment stepCount and drain the corresponding wake bucket into readyPool.
    private func advanceStep() {
        stepCount += 1
        if let waking = wakeBuckets.removeValue(forKey: stepCount) {
            readyPool.append(contentsOf: waking)
        }
    }

    /// Remove and return a random item from readyPool (also removes from activeMap).
    private func pickReadyItem() -> QueueItem? {
        guard !readyPool.isEmpty else { return nil }
        let idx = Int.random(in: 0..<readyPool.count)
        let key = readyPool.remove(at: idx)
        return activeMap.removeValue(forKey: key)
    }

    private func advanceToNextItem() {
        currentItem = nil
        prompt = nil
        currentSubject = nil

        if timerModeEnabled {
            // Fast-forward: pick any item from activeMap (TTL is irrelevant).
            guard !activeMap.isEmpty else { return }
            let key = activeMap.keys.randomElement()!
            let item = activeMap.removeValue(forKey: key)!
            wakeBuckets[item.readyAtStep]?.remove(key)
            readyPool.removeAll { $0 == key }
            setCurrentItem(item)
            return
        }

        // Normal mode: step has already been advanced by next(). Pick from ready pool / unseen.
        let hasUnseen = !unseenQueue.isEmpty
        let hasReady = !readyPool.isEmpty

        switch (hasUnseen, hasReady) {
        case (true, true):
            if Bool.random() {
                setCurrentItem(unseenQueue.removeFirst())
            } else {
                setCurrentItem(pickReadyItem()!)
            }
        case (true, false):
            setCurrentItem(unseenQueue.removeFirst())
        case (false, true):
            setCurrentItem(pickReadyItem()!)
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

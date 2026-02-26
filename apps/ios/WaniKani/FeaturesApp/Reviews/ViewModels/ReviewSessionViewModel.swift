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
        var incorrectMeaningAnswers: Int = 0
        var incorrectReadingAnswers: Int = 0
        var meaningCorrect = false
        var readingCorrect = false
        let hasReadings: Bool

        var isComplete: Bool { meaningCorrect && (readingCorrect || !hasReadings) }
    }

    private struct UndoCheckpoint {
        let previousPrompt: Prompt
        let previousSessionItem: SessionItem
        let restoredQueueItem: QueueItem
        let previousAttemptCount: Int
        let wasComplete: Bool
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
    @Published var userAnswer = ""
    @Published var timerModeEnabled: Bool = false

    // MARK: - Queue

    private var unseenQueue: [QueueItem] = []
    private var activeQueue: [QueueItem] = []
    private var currentItem: QueueItem?
    private var sessionItems: [Int: SessionItem] = [:]
    private var pendingCommit: SessionItem? = nil
    private var undoCheckpoint: UndoCheckpoint? = nil
    private var timerExpired = false

    // MARK: - Dependencies

    private let reviewSessionRepository: ReviewSessionRepositoryProtocol
    private let subjectDetailRepository: SubjectDetailRepositoryProtocol

    init(
        reviewSessionRepository: ReviewSessionRepositoryProtocol,
        subjectDetailRepository: SubjectDetailRepositoryProtocol
    ) {
        self.reviewSessionRepository = reviewSessionRepository
        self.subjectDetailRepository = subjectDetailRepository
    }

    // MARK: - Computed

    var remainingCount: Int {
        unseenQueue.count + activeQueue.count + (currentItem == nil ? 0 : 1)
    }

    var detailsAvailable: Bool { phase == .feedback }

    // MARK: - Load

    func load(policy: QueuePolicy = .normal) async {
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
        timerExpired = false

        do {
            let assignments = try await reviewSessionRepository.startReviewSession()
            if assignments.isEmpty {
                state = .empty
                return
            }

            var loadedItems: [QueueItem] = []
            var loadedSessions: [Int: SessionItem] = [:]

            for assignment in assignments {
                guard let subject = try await subjectDetailRepository.fetchSubjectDetail(id: assignment.subjectID) else {
                    continue
                }
                loadedSessions[assignment.id] = SessionItem(
                    assignmentID: assignment.id,
                    hasReadings: subject.hasReadings
                )
                loadedItems.append(QueueItem(assignment: assignment, subject: subject, questionType: .meaning))
                if subject.hasReadings {
                    loadedItems.append(QueueItem(assignment: assignment, subject: subject, questionType: .reading))
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

        let isCorrect: Bool
        switch activeItem.questionType {
        case .meaning:
            isCorrect = AnswerChecker.checkMeaning(answer, for: activeItem.subject)
        case .reading:
            isCorrect = AnswerChecker.checkReading(answer, for: activeItem.subject)
        }

        guard var sessionItem = sessionItems[activeItem.assignment.id] else {
            state = .failed("Missing session state")
            return
        }

        let previousAttemptCount = attemptHistory.count

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

        let wasComplete = sessionItem.isComplete
        sessionItems[activeItem.assignment.id] = sessionItem

        if wasComplete {
            pendingCommit = sessionItem
            sessionItems.removeValue(forKey: sessionItem.assignmentID)
        }

        undoCheckpoint = UndoCheckpoint(
            previousPrompt: prompt!,
            previousSessionItem: sessionItem,
            restoredQueueItem: activeItem,
            previousAttemptCount: previousAttemptCount,
            wasComplete: wasComplete
        )

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
            } catch {
                // Non-fatal: log and continue
            }
            pendingCommit = nil
        }

        undoCheckpoint = nil
        canUndo = false

        let queuesEmpty = activeQueue.isEmpty && unseenQueue.isEmpty && pendingCommit == nil
        if timerModeEnabled && timerExpired && queuesEmpty {
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

    func undo() {
        guard canUndo, let checkpoint = undoCheckpoint else { return }

        attemptHistory = Array(attemptHistory.prefix(checkpoint.previousAttemptCount))

        if checkpoint.wasComplete {
            pendingCommit = nil
            sessionItems[checkpoint.previousSessionItem.assignmentID] = checkpoint.previousSessionItem
        } else {
            // Item was put back in activeQueue on incorrect answer - remove it
            if let lastIdx = activeQueue.indices.last,
               activeQueue[lastIdx].assignment.id == checkpoint.restoredQueueItem.assignment.id,
               activeQueue[lastIdx].questionType == checkpoint.restoredQueueItem.questionType {
                activeQueue.removeLast()
            }
            // Restore session item to its pre-answer state
            sessionItems[checkpoint.previousSessionItem.assignmentID] = checkpoint.previousSessionItem
        }

        currentItem = checkpoint.restoredQueueItem
        currentSubject = checkpoint.restoredQueueItem.subject
        prompt = checkpoint.previousPrompt
        userAnswer = ""
        lastAnswerCorrect = nil
        undoCheckpoint = nil
        canUndo = false
        phase = .answering
    }

    // MARK: - Private

    func expireTimer() {
        timerExpired = true
    }

    private func advanceToNextItem() {
        currentItem = nil
        prompt = nil
        currentSubject = nil

        if !activeQueue.isEmpty {
            let next = activeQueue.removeFirst()
            setCurrentItem(next)
        } else if !timerExpired, !unseenQueue.isEmpty {
            let next = unseenQueue.removeFirst()
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

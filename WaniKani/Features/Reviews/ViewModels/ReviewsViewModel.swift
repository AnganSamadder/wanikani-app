import SwiftUI
import WaniKaniCore

enum QuestionType {
    case meaning, reading
}

struct ReviewItem: Identifiable, Hashable {
    let id = UUID()
    let assignment: AssignmentSnapshot
    let subject: SubjectSnapshot
    let questionType: QuestionType
}

/// Tracks review session state for a single assignment
private struct ReviewSessionItem {
    let assignmentID: Int
    let assignment: AssignmentSnapshot
    let subject: SubjectSnapshot
    
    var meaningAnsweredCorrectly = false
    var readingAnsweredCorrectly = false
    var incorrectMeaningAnswers = 0
    var incorrectReadingAnswers = 0
    
    var isComplete: Bool {
        meaningAnsweredCorrectly && (readingAnsweredCorrectly || !subject.hasReadings)
    }
}

@MainActor
class ReviewsViewModel: ObservableObject {
    enum State {
        case loading
        case empty
        case reviewing
        case complete
        case error(String)
    }
    
    enum AnswerResult {
        case correct
        case incorrect(String) // feedback message
    }
    
    @Published var state: State = .loading
    @Published var currentItem: ReviewItem?
    @Published var queue: [ReviewItem] = []
    @Published var userAnswer: String = ""
    @Published var lastAnswerResult: AnswerResult?
    @Published var isSubmitting = false
    
    // Session tracking: assignmentID -> session state
    private var sessionItems: [Int: ReviewSessionItem] = [:]
    
    // Dependencies
    private let assignmentRepo: AssignmentRepositoryProtocol
    private let subjectRepo: SubjectRepositoryProtocol
    private let reviewRepo: ReviewRepositoryProtocol
    private let logger = SmartLogger(subsystem: "com.angansamadder.wanikani", category: "Reviews")
    
    init(
        assignmentRepo: AssignmentRepositoryProtocol,
        subjectRepo: SubjectRepositoryProtocol,
        reviewRepo: ReviewRepositoryProtocol
    ) {
        self.assignmentRepo = assignmentRepo
        self.subjectRepo = subjectRepo
        self.reviewRepo = reviewRepo
        
        logger.debug("ReviewsViewModel initialized")
    }
    
    func loadReviews() async {
        state = .loading
        logger.debug("Loading reviews...")
        
        do {
            // 1. Fetch available assignments
            let assignments = try await assignmentRepo.fetchAssignments(availableBefore: Date())
            logger.debug("Fetched \(assignments.count) available assignments")
            
            if assignments.isEmpty {
                state = .empty
                return
            }
            
            // 2. Build Queue and Session Items
            var newQueue: [ReviewItem] = []
            var newSessionItems: [Int: ReviewSessionItem] = [:]
            
            for assignment in assignments {
                if let subject = try await subjectRepo.fetchSubject(id: assignment.subjectID) {
                    // Initialize session item
                    let sessionItem = ReviewSessionItem(
                        assignmentID: assignment.id,
                        assignment: assignment,
                        subject: subject
                    )
                    newSessionItems[assignment.id] = sessionItem
                    
                    // Add Meaning question
                    newQueue.append(ReviewItem(assignment: assignment, subject: subject, questionType: .meaning))
                    
                    // Add Reading question (Radicals don't have readings)
                    if subject.hasReadings {
                        newQueue.append(ReviewItem(assignment: assignment, subject: subject, questionType: .reading))
                    }
                } else {
                    logger.error("Subject not found for assignment \(assignment.id), subjectID: \(assignment.subjectID)")
                }
            }
            
            self.queue = newQueue.shuffled()
            self.sessionItems = newSessionItems
            logger.debug("Queue built with \(self.queue.count) items")
            
            if self.queue.isEmpty {
                state = .empty
            } else {
                nextItem()
                state = .reviewing
            }
            
        } catch {
            logger.error("Failed to load reviews: \(error.localizedDescription)")
            state = .error(error.localizedDescription)
        }
    }
    
    func nextItem() {
        userAnswer = ""
        lastAnswerResult = nil
        
        if queue.isEmpty {
            state = .complete
            currentItem = nil
            logger.info("Review session complete")
        } else {
            currentItem = queue.removeFirst()
            logger.debug("Next item: \(currentItem?.subject.characters ?? "nil") (\(currentItem?.questionType ?? .meaning))")
        }
    }
    
    func submitAnswer(_ answer: String) async {
        guard let item = currentItem else { return }
        guard !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSubmitting = true
        defer { isSubmitting = false }
        
        // Check answer correctness
        let isCorrect: Bool
        switch item.questionType {
        case .meaning:
            isCorrect = AnswerChecker.checkMeaning(answer, for: item.subject)
        case .reading:
            isCorrect = AnswerChecker.checkReading(answer, for: item.subject)
        }
        
        // Update session state
        guard var sessionItem = sessionItems[item.assignment.id] else {
            logger.error("Session item not found for assignment \(item.assignment.id)")
            return
        }
        
        if isCorrect {
            lastAnswerResult = .correct
            switch item.questionType {
            case .meaning:
                sessionItem.meaningAnsweredCorrectly = true
            case .reading:
                sessionItem.readingAnsweredCorrectly = true
            }
        } else {
            let correctAnswer = item.questionType == .meaning 
                ? (item.subject.primaryMeaning ?? item.subject.acceptedMeanings.first ?? "")
                : (item.subject.primaryReading ?? item.subject.acceptedReadings.first ?? "")
            lastAnswerResult = .incorrect("Correct answer: \(correctAnswer)")
            
            switch item.questionType {
            case .meaning:
                sessionItem.incorrectMeaningAnswers += 1
            case .reading:
                sessionItem.incorrectReadingAnswers += 1
            }
        }
        
        sessionItems[item.assignment.id] = sessionItem
        
        // If both parts are complete, submit review
        if sessionItem.isComplete {
            await submitReview(for: sessionItem)
        } else {
            // Wait a bit to show feedback, then advance
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            nextItem()
        }
    }
    
    private func submitReview(for sessionItem: ReviewSessionItem) async {
        logger.debug("Submitting review for assignment \(sessionItem.assignmentID)")
        
        do {
            let review = try await reviewRepo.submitReview(
                assignmentId: sessionItem.assignmentID,
                incorrectMeaningAnswers: sessionItem.incorrectMeaningAnswers,
                incorrectReadingAnswers: sessionItem.incorrectReadingAnswers
            )
            
            logger.info("Review submitted successfully: \(review.id)")
            
            // Remove this assignment from queue (remove remaining questions for this assignment)
            queue.removeAll { $0.assignment.id == sessionItem.assignmentID }
            sessionItems.removeValue(forKey: sessionItem.assignmentID)
            
            // Advance to next item
            nextItem()
            
        } catch let error as NetworkError {
            switch error {
            case .rateLimited(let retryAfter):
                logger.info("Rate limited. Retry after \(retryAfter) seconds")
                lastAnswerResult = .incorrect("Rate limited. Please wait \(retryAfter) seconds before trying again.")
            default:
                logger.error("Failed to submit review: \(error.localizedDescription)")
                lastAnswerResult = .incorrect("Failed to submit: \(error.localizedDescription)")
            }
            // Don't advance - let user retry
        } catch {
            logger.error("Failed to submit review: \(error.localizedDescription)")
            lastAnswerResult = .incorrect("Failed to submit: \(error.localizedDescription)")
            // Don't advance - let user retry
        }
    }
}

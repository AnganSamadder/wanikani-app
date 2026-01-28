import SwiftUI
import WaniKaniCore

enum QuestionType {
    case meaning, reading
}

struct ReviewItem: Identifiable, Hashable {
    let id = UUID()
    let assignment: PersistentAssignment
    let subject: PersistentSubject
    let questionType: QuestionType
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
    
    @Published var state: State = .loading
    @Published var currentItem: ReviewItem?
    @Published var queue: [ReviewItem] = []
    
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
            
            // 2. Build Queue
            var newQueue: [ReviewItem] = []
            
            for assignment in assignments {
                if let subject = try await subjectRepo.fetchSubject(id: assignment.subjectID) {
                    // Add Meaning question
                    newQueue.append(ReviewItem(assignment: assignment, subject: subject, questionType: .meaning))
                    
                    // Add Reading question (Radicals don't have readings in the review sense typically, or at least they are treated differently. But WaniKani API Subject structure for Radical has NO readings usually.
                    // subject.object is "radical", "kanji", or "vocabulary"
                    if subject.object != "radical" {
                        newQueue.append(ReviewItem(assignment: assignment, subject: subject, questionType: .reading))
                    }
                } else {
                    logger.error("Subject not found for assignment \(assignment.id), subjectID: \(assignment.subjectID)")
                }
            }
            
            self.queue = newQueue.shuffled()
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
        
        // TODO: Implement actual answer checking logic and API submission
        // For prototype, we assume correct and move on.
        // We will likely need a `ReviewSession` object to track incorrect attempts for SRS.
        
        // Simulating network delay
        try? await Task.sleep(nanoseconds: 500_000_000) 
        
        logger.debug("Submitted answer: \(answer) for item \(item.id)")
        
        // For now, just advance
        nextItem()
    }
}

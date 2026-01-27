import SwiftUI
import WaniKaniCore

enum ReviewState {
    case loading
    case empty
    case reviewing(subject: PersistentSubject, questionType: QuestionType)
    case complete
}

enum QuestionType {
    case meaning, reading
}

@MainActor
class NativeReviewsViewModel: ObservableObject {
    @Published var state: ReviewState = .loading
    @Published var userAnswer = ""
    @Published var correctCount = 0
    @Published var incorrectCount = 0
    
    private let persistence: PersistenceManager
    private let srsStateMachine: SRSStateMachine
    
    // For MVP: Fetch from persistence
    init(persistence: PersistenceManager, srsStateMachine: SRSStateMachine = SRSStateMachine()) {
        self.persistence = persistence
        self.srsStateMachine = srsStateMachine
        loadReviews()
    }
    
    func loadReviews() {
        state = .empty
    }
    
    func submitAnswer() {
        // Placeholder
    }
}

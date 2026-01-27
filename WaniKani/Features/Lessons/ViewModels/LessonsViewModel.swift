import SwiftUI
import WaniKaniCore

enum LessonState {
    case loading
    case empty
    case learning(subject: PersistentSubject)
    case quizzing(subject: PersistentSubject, questionType: QuestionType)
    case complete
}

@MainActor
class LessonsViewModel: ObservableObject {
    @Published var state: LessonState = .loading
    @Published var userAnswer = ""
    
    private let persistence: PersistenceManager
    private var lessonQueue: [PersistentAssignment] = []
    
    init(persistence: PersistenceManager) {
        self.persistence = persistence
        loadLessons()
    }
    
    func loadLessons() {
        // Fetch assignments where srsStage == 0 and startedAt == nil
        // For MVP stub:
        state = .empty
    }
    
    func startSession() {
        // Transition from empty/summary to first lesson
    }
    
    func submitAnswer() {
        // Handle quiz answer
    }
}

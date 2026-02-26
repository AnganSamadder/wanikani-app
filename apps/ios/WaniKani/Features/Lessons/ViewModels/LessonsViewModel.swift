import SwiftUI
import WaniKaniCore

enum LessonState {
    case loading
    case empty
    case learning(lessonItem: LessonItem)
    case quizzing(lessonItem: LessonItem, questionType: QuestionType)
    case complete
}

struct LessonItem: Identifiable {
    let id: Int
    let assignment: AssignmentSnapshot
    let subject: SubjectSnapshot
}

@MainActor
class LessonsViewModel: ObservableObject {
    @Published var state: LessonState = .loading
    @Published var userAnswer = ""
    @Published var currentLessonIndex = 0
    @Published var lessonItems: [LessonItem] = []
    
    private let persistence: PersistenceManager
    private let subjectRepo: SubjectRepositoryProtocol
    private let api: WaniKaniAPI
    private let logger = SmartLogger(subsystem: "com.angansamadder.wanikani", category: "Lessons")
    
    init(persistence: PersistenceManager, subjectRepo: SubjectRepositoryProtocol, api: WaniKaniAPI) {
        self.persistence = persistence
        self.subjectRepo = subjectRepo
        self.api = api
        Task {
            await loadLessons()
        }
    }
    
    func loadLessons() async {
        state = .loading
        logger.debug("Loading lessons...")
        
        // Fetch lesson assignments from persistence
        let assignments = persistence.fetchLessonAssignmentSnapshots(now: Date())
        logger.debug("Found \(assignments.count) lesson assignments")
        
        if assignments.isEmpty {
            state = .empty
            return
        }
        
        // Fetch subjects for assignments
        var items: [LessonItem] = []
        for assignment in assignments {
            if let subject = try? await subjectRepo.fetchSubject(id: assignment.subjectID) {
                items.append(LessonItem(id: assignment.id, assignment: assignment, subject: subject))
            } else {
                logger.error("Subject not found for assignment \(assignment.id)")
            }
        }
        
        self.lessonItems = items
        
        if items.isEmpty {
            state = .empty
        } else {
            startSession()
        }
    }
    
    func startSession() {
        guard !lessonItems.isEmpty else {
            state = .empty
            return
        }
        currentLessonIndex = 0
        showCurrentLesson()
    }
    
    private func showCurrentLesson() {
        guard currentLessonIndex < lessonItems.count else {
            completeSession()
            return
        }
        
        let item = lessonItems[currentLessonIndex]
        state = .learning(lessonItem: item)
    }
    
    func nextLesson() {
        currentLessonIndex += 1
        userAnswer = ""
        showCurrentLesson()
    }
    
    func startQuiz() {
        guard currentLessonIndex < lessonItems.count else { return }
        let item = lessonItems[currentLessonIndex]
        state = .quizzing(lessonItem: item, questionType: .meaning)
    }
    
    func submitAnswer(_ answer: String) async {
        guard case .quizzing(let item, let questionType) = state else { return }
        
        let isCorrect: Bool
        switch questionType {
        case .meaning:
            isCorrect = AnswerChecker.checkMeaning(answer, for: item.subject)
        case .reading:
            isCorrect = AnswerChecker.checkReading(answer, for: item.subject)
        }
        
        if isCorrect {
            // Move to next question type or next lesson
            if questionType == .meaning && item.subject.hasReadings {
                state = .quizzing(lessonItem: item, questionType: .reading)
            } else {
                // Lesson complete, move to next
                await completeCurrentLesson()
            }
        } else {
            // Show error, allow retry (for now just show feedback)
            logger.debug("Incorrect answer: \(answer)")
        }
        
        userAnswer = ""
    }
    
    private func completeCurrentLesson() async {
        guard currentLessonIndex < lessonItems.count else { return }
        
        let item = lessonItems[currentLessonIndex]
        
        // Call startAssignment API
        do {
            let updatedAssignment = try await api.startAssignment(id: item.assignment.id)
            logger.info("Started assignment \(item.assignment.id)")
            
            // Update persistence
            persistence.saveAssignments([updatedAssignment])
            
            // Move to next lesson
            nextLesson()
        } catch {
            logger.error("Failed to start assignment: \(error.localizedDescription)")
            // Still advance to avoid blocking
            nextLesson()
        }
    }
    
    private func completeSession() {
        state = .complete
        logger.info("Lesson session complete")
    }
}

import Foundation
import SwiftUI
import WaniKaniCore

@MainActor
final class LessonSessionViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case studying
        case quizzing
        case empty
        case complete
        case failed(String)
    }

    enum QuestionType {
        case meaning
        case reading
    }

    enum Feedback: Equatable {
        case none
        case correct
        case incorrect(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var feedback: Feedback = .none
    @Published var userAnswer = ""

    private let repository: LessonSessionRepositoryProtocol
    private var queue: [SubjectSnapshot] = []
    private var currentIndex = 0
    private var questionType: QuestionType = .meaning
    private var loadTask: Task<Void, Never>? = nil

    init(repository: LessonSessionRepositoryProtocol) {
        self.repository = repository
    }

    var currentSubject: SubjectSnapshot? {
        guard currentIndex < queue.count else { return nil }
        return queue[currentIndex]
    }

    var progressText: String {
        guard !queue.isEmpty else { return "0/0" }
        return "\(min(currentIndex + 1, queue.count))/\(queue.count)"
    }

    var questionLabel: String {
        questionType == .meaning ? "Meaning" : "Reading"
    }

    var questionPlaceholder: String {
        questionType == .meaning ? "Type the meaning" : "Type the reading"
    }

    func load() async {
        if let loadTask {
            await loadTask.value
            return
        }

        let task = Task { [self] in
            await performLoad()
        }
        loadTask = task
        await task.value
        loadTask = nil
    }

    func prefetchIfNeeded() async {
        guard state == .idle else { return }
        await load()
    }

    private func performLoad() async {
        state = .loading
        feedback = .none
        userAnswer = ""

        do {
            queue = try await repository.fetchLessonQueue()
            currentIndex = 0
            questionType = .meaning

            if queue.isEmpty {
                state = .empty
            } else {
                state = .studying
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func startQuiz() {
        guard currentSubject != nil else {
            state = .empty
            return
        }

        questionType = .meaning
        feedback = .none
        userAnswer = ""
        state = .quizzing
    }

    func submitCurrentAnswer() {
        guard state == .quizzing,
              let subject = currentSubject,
              !userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        let answer = userAnswer
        userAnswer = ""

        let isCorrect: Bool
        switch questionType {
        case .meaning:
            isCorrect = AnswerChecker.checkMeaning(answer, for: subject)
        case .reading:
            isCorrect = AnswerChecker.checkReading(answer, for: subject)
        }

        if isCorrect {
            feedback = .correct

            if questionType == .meaning && subject.hasReadings {
                questionType = .reading
            } else {
                moveToNextSubject()
            }
        } else {
            let expected = questionType == .meaning
                ? (subject.primaryMeaning ?? subject.acceptedMeanings.first ?? "N/A")
                : (subject.primaryReading ?? subject.acceptedReadings.first ?? "N/A")
            feedback = .incorrect(expected)
        }
    }

    func nextSubjectWithoutQuiz() {
        moveToNextSubject()
    }

    private func moveToNextSubject() {
        feedback = .none
        questionType = .meaning
        currentIndex += 1

        if currentIndex >= queue.count {
            state = .complete
        } else {
            state = .studying
        }
    }
}

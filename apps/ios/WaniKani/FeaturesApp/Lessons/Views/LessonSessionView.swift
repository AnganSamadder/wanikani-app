import SwiftUI

struct LessonSessionView: View {
    @StateObject private var viewModel: LessonSessionViewModel

    init(viewModel: LessonSessionViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        AppScreen(title: viewModel.currentSubject?.characters ?? "Lessons", subtitle: "\(viewModel.progressText) • \(viewModel.questionLabel)") {
            AppSectionTitle(icon: "book.fill", text: "Lesson Queue")

            switch viewModel.state {
            case .idle, .loading:
                ProgressView("Loading lessons...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            case .empty:
                AppCard {
                    Text("No lessons available")
                        .font(.headline.weight(.semibold))
                    Text("When assignments unlock, they will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            case .complete:
                AppCard {
                    Text("Lesson session complete")
                        .font(.headline.weight(.semibold))
                    Text("You’ve finished all queued lessons.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            case .failed(let message):
                AppCard {
                    Text("Unable to load lessons")
                        .font(.headline.weight(.semibold))
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    AppPrimaryButton(title: "Retry") {
                        Task { await viewModel.load() }
                    }
                }
            case .studying:
                lessonContent
                AppPrimaryButton(title: "Start Quiz") {
                    viewModel.startQuiz()
                }
            case .quizzing:
                lessonContent
                answerCard
                AppPrimaryButton(title: "Submit") {
                    viewModel.submitCurrentAnswer()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.state == .idle {
                await viewModel.load()
            }
        }
    }

    @ViewBuilder
    private var lessonContent: some View {
        if let subject = viewModel.currentSubject {
            AppCard {
                Text(subject.primaryMeaning ?? subject.slug)
                    .font(.headline.weight(.semibold))
                HStack(spacing: 10) {
                    AppTagPill(title: subject.object.capitalized, tint: WKColor.forSubjectType(subject.object))
                    AppTagPill(title: "Level \(subject.level)", tint: WKColor.kanji)
                }
                if subject.readings.isEmpty {
                    Text("No readings required for this subject.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(subject.readings.map(\.reading).joined(separator: " • "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var answerCard: some View {
        AppCard {
            Text(viewModel.questionLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField(viewModel.questionPlaceholder, text: $viewModel.userAnswer)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardDoneButton()
                .font(.title3)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: max(8, AppTheme.cardRadius - 2), style: .continuous))

            switch viewModel.feedback {
            case .none:
                EmptyView()
            case .correct:
                Text("Correct")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(WKColor.success)
            case .incorrect(let expected):
                Text("Incorrect. Expected: \(expected)")
                    .font(.subheadline)
                    .foregroundStyle(WKColor.error)
            }
        }
    }
}

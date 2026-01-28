import SwiftUI
import WaniKaniCore

struct LessonsView: View {
    @StateObject private var viewModel: LessonsViewModel
    
    init() {
        let persistence = PersistenceManager.shared
        let subjectRepo = SubjectRepository(persistenceManager: persistence)
        let apiToken = AuthenticationManager.shared.apiToken ?? ""
        let api = WaniKaniAPI(networkClient: URLSessionNetworkClient(), apiToken: apiToken)
        
        _viewModel = StateObject(wrappedValue: LessonsViewModel(persistence: persistence, subjectRepo: subjectRepo, api: api))
    }
    
    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                loadingState
            case .empty:
                emptyState
            case .learning(let lessonItem):
                LessonCardView(
                    subject: lessonItem.subject,
                    onContinue: {
                        // Transition to quiz
                        viewModel.startQuiz()
                    }
                )
            case .quizzing(let lessonItem, let questionType):
                LessonQuizView(
                    subject: lessonItem.subject,
                    questionType: questionType,
                    answer: $viewModel.userAnswer,
                    onSubmit: {
                        Task {
                            await viewModel.submitAnswer(viewModel.userAnswer)
                        }
                    }
                )
            case .complete:
                completeState
            }
        }
        .background(WKColor.surfacePrimary)
        .navigationTitle("Lessons")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Loading State
    
    private var loadingState: some View {
        VStack(spacing: WKSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading Lessons...")
                .font(WKTypography.body)
                .foregroundStyle(WKColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        WKEmptyState.noContent(
            title: "No Lessons Available",
            message: "Complete some reviews to unlock new lessons, or check back later."
        )
    }
    
    // MARK: - Complete State
    
    private var completeState: some View {
        VStack(spacing: WKSpacing.xl) {
            ZStack {
                Circle()
                    .fill(WKColor.success.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(WKColor.success)
            }
            
            VStack(spacing: WKSpacing.xs) {
                Text("Lessons Complete!")
                    .font(WKTypography.title)
                    .foregroundStyle(WKColor.textPrimary)
                
                Text("You've learned new items. They'll appear in your reviews soon.")
                    .font(WKTypography.body)
                    .foregroundStyle(WKColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            WKButton("Continue", style: .primary, size: .large) {
                Task {
                    await viewModel.loadLessons()
                }
            }
        }
        .padding(WKSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Lesson Card View (Learning Mode)

private struct LessonCardView: View {
    let subject: SubjectSnapshot
    let onContinue: () -> Void
    
    @State private var currentPage = 0
    
    private var subjectColor: Color {
        WKColor.forSubjectType(subject.object)
    }
    
    private var subjectBackgroundColor: Color {
        WKColor.backgroundForSubjectType(subject.object)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with subject info
            headerSection
            
            // Content area (scrollable)
            ScrollView {
                VStack(spacing: WKSpacing.xl) {
                    // Character display
                    characterSection
                    
                    // Meaning section
                    meaningSection
                    
                    // Reading section (if applicable)
                    if subject.object != "radical" {
                        readingSection
                    }
                }
                .padding(.horizontal, WKSpacing.lg)
                .padding(.vertical, WKSpacing.xl)
            }
            
            // Continue button
            footerSection
        }
    }
    
    private var headerSection: some View {
        HStack {
            WKBadge.subject(subject.object)
            
            Spacer()
            
            Text("Level \(subject.level)")
                .font(WKTypography.captionMedium)
                .foregroundStyle(WKColor.textTertiary)
        }
        .padding(.horizontal, WKSpacing.lg)
        .padding(.vertical, WKSpacing.md)
        .background(WKColor.surfaceSecondary)
    }
    
    private var characterSection: some View {
        VStack(spacing: WKSpacing.md) {
            Text(subject.characters ?? subject.slug)
                .font(WKTypography.japaneseLarge)
                .foregroundStyle(WKColor.textPrimary)
            
            let primaryMeaning = subject.meanings.first(where: { $0.primary })?.meaning ?? subject.meanings.first?.meaning ?? ""
            Text(primaryMeaning)
                .font(WKTypography.titleMedium)
                .foregroundStyle(subjectColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, WKSpacing.xxl)
        .background(subjectBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: WKRadius.lg, style: .continuous))
    }
    
    private var meaningSection: some View {
        VStack(alignment: .leading, spacing: WKSpacing.sm) {
            SectionHeader(title: "Meanings", icon: "text.book.closed.fill")
            
            VStack(alignment: .leading, spacing: WKSpacing.xs) {
                ForEach(subject.meanings.indices, id: \.self) { index in
                    let meaning = subject.meanings[index]
                    HStack(spacing: WKSpacing.xs) {
                        Text(meaning.meaning)
                            .font(meaning.primary ? WKTypography.bodyLarge : WKTypography.body)
                            .foregroundStyle(meaning.primary ? WKColor.textPrimary : WKColor.textSecondary)
                        
                        if meaning.primary {
                            Text("Primary")
                                .font(WKTypography.caption)
                                .foregroundStyle(subjectColor)
                                .padding(.horizontal, WKSpacing.xs)
                                .padding(.vertical, 2)
                                .background(subjectBackgroundColor)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var readingSection: some View {
        VStack(alignment: .leading, spacing: WKSpacing.sm) {
            SectionHeader(title: "Readings", icon: "speaker.wave.2.fill")
            
            VStack(alignment: .leading, spacing: WKSpacing.xs) {
                ForEach(subject.readings.indices, id: \.self) { index in
                    let reading = subject.readings[index]
                    HStack(spacing: WKSpacing.sm) {
                        Text(reading.reading)
                            .font(.system(size: 20, design: .rounded))
                            .foregroundStyle(reading.primary ? WKColor.textPrimary : WKColor.textSecondary)
                        
                        if let type = reading.type {
                            Text(type.capitalized)
                                .font(WKTypography.caption)
                                .foregroundStyle(WKColor.textTertiary)
                        }
                        
                        if reading.primary {
                            Text("Primary")
                                .font(WKTypography.caption)
                                .foregroundStyle(subjectColor)
                                .padding(.horizontal, WKSpacing.xs)
                                .padding(.vertical, 2)
                                .background(subjectBackgroundColor)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var footerSection: some View {
        VStack(spacing: 0) {
            Divider()
            
            WKButton("Ready to Quiz", icon: "arrow.right", style: .primary, size: .large, isFullWidth: true) {
                onContinue()
            }
            .padding(WKSpacing.lg)
        }
        .background(WKColor.surfacePrimary)
    }
    
}

// MARK: - Lesson Quiz View

private struct LessonQuizView: View {
    let subject: SubjectSnapshot
    let questionType: QuestionType
    @Binding var answer: String
    let onSubmit: () -> Void
    
    @FocusState private var isInputFocused: Bool
    
    private var subjectColor: Color {
        WKColor.forSubjectType(subject.object)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Subject display
            VStack(spacing: WKSpacing.md) {
                WKBadge.subject(subject.object)
                
                Text(subject.characters ?? subject.slug)
                    .font(WKTypography.japanese)
                    .foregroundStyle(WKColor.textPrimary)
            }
            .padding(WKSpacing.xl)
            
            // Question prompt
            HStack(spacing: WKSpacing.xs) {
                Circle()
                    .fill(questionType == .meaning ? WKColor.textSecondary : subjectColor)
                    .frame(width: 8, height: 8)
                
                Text(questionType == .meaning ? "What is the meaning?" : "What is the reading?")
                    .font(WKTypography.bodyMedium)
                    .foregroundStyle(WKColor.textSecondary)
            }
            
            Spacer()
            
            // Answer input
            VStack(spacing: WKSpacing.md) {
                TextField(
                    questionType == .meaning ? "Enter meaning" : "Enter reading",
                    text: $answer
                )
                .font(WKTypography.titleMedium)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isInputFocused)
                .submitLabel(.done)
                .onSubmit(onSubmit)
                .padding(WKSpacing.md)
                .background(WKColor.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: WKRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: WKRadius.md, style: .continuous)
                        .strokeBorder(questionType == .meaning ? WKColor.border : subjectColor, lineWidth: 2)
                )
                
                WKButton("Submit", style: .primary, size: .large, isFullWidth: true) {
                    onSubmit()
                }
                .disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, WKSpacing.lg)
            .padding(.bottom, WKSpacing.xxl)
        }
        .onAppear {
            isInputFocused = true
        }
    }
}

// MARK: - Supporting Views

private struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: WKSpacing.xs) {
            Image(systemName: icon)
                .font(WKTypography.captionMedium)
                .foregroundStyle(WKColor.textTertiary)
            
            Text(title)
                .font(WKTypography.captionMedium)
                .foregroundStyle(WKColor.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
    }
}

#Preview {
    NavigationStack {
        LessonsView()
    }
}

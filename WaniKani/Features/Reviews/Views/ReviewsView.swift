import SwiftUI
import WaniKaniCore

struct ReviewsView: View {
    @StateObject private var viewModel: ReviewsViewModel
    
    init() {
        let persistence = PersistenceManager.shared
        let apiToken = AuthenticationManager.shared.apiToken ?? ""
        let api = WaniKaniAPI(networkClient: URLSessionNetworkClient(), apiToken: apiToken)
        
        let assignmentRepo = AssignmentRepository(persistenceManager: persistence)
        let subjectRepo = SubjectRepository(persistenceManager: persistence)
        let reviewRepo = ReviewRepository(api: api)
        
        _viewModel = StateObject(wrappedValue: ReviewsViewModel(
            assignmentRepo: assignmentRepo,
            subjectRepo: subjectRepo,
            reviewRepo: reviewRepo
        ))
    }
    
    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                loadingState
            case .empty:
                emptyState
            case .reviewing:
                if let item = viewModel.currentItem {
                    reviewingState(item: item)
                } else {
                    loadingState
                }
            case .complete:
                completeState
            case .error(let message):
                errorState(message: message)
            }
        }
        .background(WKColor.surfacePrimary)
        .navigationTitle("Reviews")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if case .loading = viewModel.state {
                await viewModel.loadReviews()
            }
        }
    }
    
    // MARK: - Loading State
    
    private var loadingState: some View {
        VStack(spacing: WKSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading Reviews...")
                .font(WKTypography.body)
                .foregroundStyle(WKColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        WKEmptyState.allCaughtUp(
            title: "No Reviews",
            message: "You're all caught up! Check back later."
        )
    }
    
    // MARK: - Reviewing State (Focus Mode)
    
    private func reviewingState(item: ReviewItem) -> some View {
        ReviewCard(
            item: item,
            queueCount: viewModel.queue.count,
            onSubmit: { answer in
                Task {
                    await viewModel.submitAnswer(answer)
                }
            }
        )
    }
    
    // MARK: - Complete State
    
    private var completeState: some View {
        VStack(spacing: WKSpacing.xl) {
            Image(systemName: "star.fill")
                .font(.system(size: 64))
                .foregroundStyle(WKColor.success)
            
            VStack(spacing: WKSpacing.xs) {
                Text("Session Complete!")
                    .font(WKTypography.title)
                    .foregroundStyle(WKColor.textPrimary)
                
                Text("Great work on your reviews")
                    .font(WKTypography.body)
                    .foregroundStyle(WKColor.textSecondary)
            }
            
            WKButton("Done", style: .primary, size: .large) {
                // Navigate back or reset
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(WKSpacing.xl)
    }
    
    // MARK: - Error State
    
    private func errorState(message: String) -> some View {
        WKEmptyState.error(message: message) {
            Task {
                await viewModel.loadReviews()
            }
        }
    }
}

// MARK: - Review Card (Focus Mode)

private struct ReviewCard: View {
    let item: ReviewItem
    let queueCount: Int
    let onSubmit: (String) -> Void
    
    @State private var answer = ""
    @State private var feedback: WKAnswerField.AnswerFeedback?
    @State private var showFeedback = false
    @FocusState private var isInputFocused: Bool
    
    private var subjectColor: Color {
        WKColor.forSubjectType(item.subject.object)
    }
    
    private var subjectBackgroundColor: Color {
        WKColor.backgroundForSubjectType(item.subject.object)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            progressHeader
            
            Spacer()
            
            // Main content - Subject display
            subjectDisplay
            
            Spacer()
            
            // Question type indicator
            questionTypeIndicator
            
            Spacer()
                .frame(height: WKSpacing.xl)
            
            // Answer input
            answerInput
            
            Spacer()
                .frame(height: WKSpacing.xxl)
        }
        .padding(.horizontal, WKSpacing.lg)
        .padding(.vertical, WKSpacing.md)
        .onAppear {
            // Auto-focus input after brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isInputFocused = true
            }
        }
        .onChange(of: item.id) {
            // Reset state when item changes
            answer = ""
            feedback = nil
            showFeedback = false
            isInputFocused = true
        }
    }
    
    private var progressHeader: some View {
        HStack {
            WKSessionProgress(
                current: 1,
                total: queueCount + 1,
                color: subjectColor
            )
        }
        .padding(.horizontal, WKSpacing.xs)
    }
    
    private var subjectDisplay: some View {
        VStack(spacing: WKSpacing.md) {
            // Subject type badge
            WKBadge.subject(item.subject.object)
            
            // Character display
            Text(item.subject.characters ?? item.subject.slug)
                .font(WKTypography.japaneseLarge)
                .foregroundStyle(WKColor.textPrimary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            
            // Primary meaning hint (for reading questions)
            if item.questionType == .reading, let meaning = item.subject.primaryMeaning {
                Text(meaning)
                    .font(WKTypography.body)
                    .foregroundStyle(WKColor.textTertiary)
            }
        }
        .padding(WKSpacing.xl)
        .frame(maxWidth: .infinity)
        .background(subjectBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: WKRadius.lg, style: .continuous))
    }
    
    private var questionTypeIndicator: some View {
        HStack(spacing: WKSpacing.xs) {
            Circle()
                .fill(item.questionType == .meaning ? WKColor.textSecondary : subjectColor)
                .frame(width: 8, height: 8)
            
            Text(item.questionType == .meaning ? "Meaning" : "Reading")
                .font(WKTypography.bodyMedium)
                .foregroundStyle(item.questionType == .meaning ? WKColor.textSecondary : subjectColor)
        }
        .padding(.horizontal, WKSpacing.md)
        .padding(.vertical, WKSpacing.xs)
        .background(
            Capsule()
                .fill(item.questionType == .meaning ? WKColor.surfaceSecondary : subjectBackgroundColor)
        )
    }
    
    private var answerInput: some View {
        VStack(spacing: WKSpacing.md) {
            TextField(
                item.questionType == .meaning ? "Enter meaning" : "Enter reading",
                text: $answer
            )
            .font(WKTypography.titleMedium)
            .multilineTextAlignment(.center)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($isInputFocused)
            .submitLabel(.done)
            .onSubmit(submitAnswer)
            .padding(WKSpacing.md)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: WKRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: WKRadius.md, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 2)
            )
            .animation(WKAnimation.quick, value: feedback)
            
            // Feedback message
            if showFeedback, let feedback = feedback {
                feedbackMessage(for: feedback)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private var backgroundColor: Color {
        guard let feedback = feedback else {
            return WKColor.surfaceSecondary
        }
        switch feedback {
        case .correct:
            return WKColor.success.opacity(0.12)
        case .incorrect:
            return WKColor.error.opacity(0.12)
        case .almostCorrect:
            return WKColor.warning.opacity(0.12)
        }
    }
    
    private var borderColor: Color {
        guard let feedback = feedback else {
            return item.questionType == .meaning ? WKColor.border : subjectColor
        }
        switch feedback {
        case .correct:
            return WKColor.success
        case .incorrect:
            return WKColor.error
        case .almostCorrect:
            return WKColor.warning
        }
    }
    
    private func feedbackMessage(for feedback: WKAnswerField.AnswerFeedback) -> some View {
        HStack(spacing: WKSpacing.xs) {
            Image(systemName: feedbackIcon(for: feedback))
            Text(feedbackText(for: feedback))
        }
        .font(WKTypography.bodyMedium)
        .foregroundStyle(feedbackColor(for: feedback))
    }
    
    private func feedbackIcon(for feedback: WKAnswerField.AnswerFeedback) -> String {
        switch feedback {
        case .correct: return "checkmark.circle.fill"
        case .incorrect: return "xmark.circle.fill"
        case .almostCorrect: return "exclamationmark.circle.fill"
        }
    }
    
    private func feedbackText(for feedback: WKAnswerField.AnswerFeedback) -> String {
        switch feedback {
        case .correct: return "Correct!"
        case .incorrect: return "Incorrect"
        case .almostCorrect(let hint): return hint
        }
    }
    
    private func feedbackColor(for feedback: WKAnswerField.AnswerFeedback) -> Color {
        switch feedback {
        case .correct: return WKColor.success
        case .incorrect: return WKColor.error
        case .almostCorrect: return WKColor.warning
        }
    }
    
    private func submitAnswer() {
        let trimmedAnswer = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAnswer.isEmpty else { return }
        
        // For prototype: simulate correct answer
        feedback = .correct
        showFeedback = true
        
        // Proceed to next after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            onSubmit(trimmedAnswer)
        }
    }
}

// MARK: - PersistentSubject Extension

extension PersistentSubject {
    var primaryMeaning: String? {
        meanings.first(where: { $0.primary })?.meaning ?? meanings.first?.meaning
    }
}

#Preview {
    NavigationStack {
        ReviewsView()
    }
}

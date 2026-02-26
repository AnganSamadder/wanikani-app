import Foundation
import SwiftUI
import WaniKaniCore

struct ReviewSessionView: View {
    @StateObject private var viewModel: ReviewSessionViewModel
    @StateObject private var audioService = AudioPlaybackService()
    @StateObject private var enrichmentManager = LinguisticEnrichmentManager()
    @AppStorage("undoButtonEnabled") private var undoButtonEnabled: Bool = true
    @State private var showingHistory = false
    @State private var enrichmentBySubjectID: [Int: EnrichedDetail] = [:]
    @State private var enrichmentInFlight: Set<Int> = []
    @FocusState private var isInputFocused: Bool
    let onNavigateToTab: ((AppRoute) -> Void)?

    init(viewModel: ReviewSessionViewModel, onNavigateToTab: ((AppRoute) -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onNavigateToTab = onNavigateToTab
    }

    // MARK: - Computed

    /// Katakana for on'yomi reading prompts, hiragana otherwise.
    private var readingScript: RomajiKanaConverter.KanaScript {
        guard viewModel.prompt?.questionType == .reading,
              let primaryType = viewModel.currentSubject?.readings.first(where: { $0.primary })?.type else {
            return .hiragana
        }
        return primaryType == "onyomi" ? .katakana : .hiragana
    }

    private var subjectTint: Color {
        WKColor.forSubjectType(viewModel.currentSubject?.object ?? "")
    }

    private var actionTint: Color {
        WKColor.kanji
    }

    private var headerTint: Color? {
        guard let type = viewModel.currentSubject?.object ?? viewModel.prompt?.subjectType else {
            return nil
        }
        return WKColor.forSubjectType(type)
    }

    private var headerTrailingText: String? {
        guard viewModel.state == .ready else { return nil }
        return "\(viewModel.remainingCount) left"
    }

    private func displayReading(_ reading: String, type: String?) -> String {
        guard type?.lowercased() == "onyomi" else { return reading }
        return reading.applyingTransform(.hiraganaToKatakana, reverse: false) ?? reading
    }

    // MARK: - Body

    var body: some View {
        AppScreen(
            title: viewModel.prompt?.subjectCharacters ?? "Reviews",
            subtitle: viewModel.prompt?.title ?? "Session",
            headerTint: headerTint,
            headerTrailingText: headerTrailingText
        ) {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView("Loading review queue...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 24)

            case .ready:
                readyContent

            case .empty:
                AppCard {
                    Text("No reviews available.")
                        .font(.body)
                    Text("Sync assignments to begin a review session.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

            case .complete:
                AppCard {
                    Text("Session complete")
                        .font(.headline.weight(.semibold))
                    Text("Great work. You finished every available review.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

            case .failed(let message):
                AppCard {
                    Text("Unable to start reviews")
                        .font(.headline.weight(.semibold))
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    AppPrimaryButton(title: "Retry") {
                        Task { await viewModel.load() }
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .onTapGesture { isInputFocused = false }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingHistory) {
            SessionHistoryPanel(records: viewModel.attemptHistory)
        }
        .task {
            if viewModel.state == .idle {
                await viewModel.load()
            }
            await prefetchEnrichmentIfNeeded(for: viewModel.currentSubject)
        }
        .onChange(of: viewModel.navigateToTab) { _, newRoute in
            if let route = newRoute {
                onNavigateToTab?(route)
            }
        }
        .onChange(of: viewModel.currentSubject?.id) { _, _ in
            Task {
                await prefetchEnrichmentIfNeeded(for: viewModel.currentSubject)
            }
        }
        .environmentObject(audioService)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button {
                Task { await viewModel.setTimerModeEnabled(!viewModel.timerModeEnabled) }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.timerModeEnabled ? "forward.fill" : "forward")
                    if viewModel.timerModeEnabled && viewModel.pendingHalfCompletionCount > 0 {
                        Text("\(viewModel.pendingHalfCompletionCount)")
                            .font(.caption.monospacedDigit())
                            .fontWeight(.semibold)
                    }
                }
            }
            .foregroundStyle(viewModel.pendingHalfCompletionCount == 0 ? WKColor.textTertiary : actionTint)
            .disabled(viewModel.pendingHalfCompletionCount == 0)

            // Session history
            Button {
                showingHistory = true
            } label: {
                Image(systemName: "checkmark.circle")
            }
            .foregroundStyle(actionTint)
        }
    }

    // MARK: - Ready content

    @ViewBuilder
    private var readyContent: some View {
        // Answer / feedback card
        AppCard {
            if viewModel.phase == .answering {
                answeringInput
            } else {
                feedbackDisplay
            }
        }

        // Keep navigation actions above details so answer flow stays primary.
        actionButtons

        if viewModel.phase == .feedback, let subject = viewModel.currentSubject {
            SubjectDetailsPanel(
                subject: subject,
                reviewViewModel: viewModel,
                prefetchedEnrichment: enrichmentBySubjectID[subject.id]
            )
        }
    }

    // MARK: - Answering input

    @ViewBuilder
    private var answeringInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.prompt?.placeholder ?? "Enter answer")
                .font(.caption)
                .foregroundStyle(.secondary)

            Group {
                if viewModel.prompt?.questionType == .reading {
                    RomajiTextField(
                        text: $viewModel.userAnswer,
                        placeholder: viewModel.prompt?.placeholder ?? "Enter reading",
                        targetScript: readingScript,
                        isFocused: $isInputFocused
                    )
                } else {
                    TextField(
                        viewModel.prompt?.placeholder ?? "Enter meaning",
                        text: $viewModel.userAnswer
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isInputFocused)
                    .onTapGesture { isInputFocused = true }
                }
            }
            .font(.title3)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: max(8, AppTheme.cardRadius - 2), style: .continuous))
            .onSubmit {
                Task { await viewModel.submitCurrentAnswer() }
            }
        }
    }

    // MARK: - Feedback display

    @ViewBuilder
    private var feedbackDisplay: some View {
        VStack(spacing: 6) {
            Text(viewModel.userAnswer.isEmpty ? "—" : viewModel.userAnswer)
                .font(.title3.weight(.medium))
                .foregroundStyle(viewModel.lastAnswerCorrect == true ? WKColor.success : WKColor.error)

            if viewModel.lastAnswerCorrect == false {
                let expected: String = {
                    switch viewModel.prompt?.questionType {
                    case .meaning: return viewModel.currentSubject?.primaryMeaning ?? "—"
                    case .reading:
                        if let primary = viewModel.currentSubject?.readings.first(where: { $0.primary }) {
                            return displayReading(primary.reading, type: primary.type)
                        }
                        return viewModel.currentSubject?.primaryReading ?? "—"
                    case .none:    return "—"
                    }
                }()
                Text("Correct: \(expected)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Action buttons

    @ViewBuilder
    private var actionButtons: some View {
        if viewModel.phase == .answering {
            AppPrimaryButton(
                title: viewModel.isSubmitting ? "Submitting..." : "Submit",
                tint: actionTint
            ) {
                Task { await viewModel.submitCurrentAnswer() }
            }
        } else {
            HStack(spacing: 12) {
                if viewModel.canUndo && undoButtonEnabled {
                    Button("← Undo") {
                        Task { await viewModel.undo() }
                    }
                    .buttonStyle(.bordered)
                    .tint(WKColor.warning)
                }

                AppPrimaryButton(title: "Next →", tint: actionTint) {
                    Task { await viewModel.next() }
                }
            }
        }
    }

    // MARK: - Enrichment prefetch

    @MainActor
    private func prefetchEnrichmentIfNeeded(for subject: SubjectSnapshot?) async {
        guard let subject else { return }
        let subjectID = subject.id
        guard enrichmentBySubjectID[subjectID] == nil else { return }
        guard !enrichmentInFlight.contains(subjectID) else { return }

        enrichmentInFlight.insert(subjectID)
        let enriched = await enrichmentManager.enrich(subject: subject)
        enrichmentBySubjectID[subjectID] = enriched
        enrichmentInFlight.remove(subjectID)
    }
}

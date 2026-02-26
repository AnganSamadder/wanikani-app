import SwiftUI
import WaniKaniCore

struct ReviewSessionView: View {
    @StateObject private var viewModel: ReviewSessionViewModel
    @StateObject private var audioService = AudioPlaybackService()
    @State private var showingHistory = false
    @State private var showingDetails = false
    @State private var timerSecondsRemaining: Int = 600
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

    private var timerFormatted: String {
        let m = timerSecondsRemaining / 60
        let s = timerSecondsRemaining % 60
        return String(format: "%d:%02d", m, s)
    }

    private var timerIsLow: Bool { timerSecondsRemaining < 60 }

    // MARK: - Body

    var body: some View {
        AppScreen(
            title: viewModel.prompt?.subjectCharacters ?? "Reviews",
            subtitle: viewModel.prompt?.title ?? "Session"
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingHistory) {
            SessionHistoryPanel(records: viewModel.attemptHistory)
        }
        .task {
            if viewModel.state == .idle {
                await viewModel.load()
            }
        }
        // Auto-open details on feedback, close on answering
        .onChange(of: viewModel.phase) { _, phase in
            showingDetails = (phase == .feedback)
        }
        // Reset countdown when timer mode is switched on
        .onChange(of: viewModel.timerModeEnabled) { _, enabled in
            if enabled { timerSecondsRemaining = 600 }
        }
        // Tick the countdown every second
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            guard viewModel.timerModeEnabled, timerSecondsRemaining > 0 else { return }
            timerSecondsRemaining -= 1
            if timerSecondsRemaining == 0 {
                viewModel.expireTimer()
            }
        }
        .onChange(of: viewModel.navigateToTab) { _, newRoute in
            if let route = newRoute {
                onNavigateToTab?(route)
            }
        }
        .environmentObject(audioService)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            // Timer toggle — shows countdown when active
            Button {
                viewModel.timerModeEnabled.toggle()
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: viewModel.timerModeEnabled ? "clock.fill" : "clock")
                    if viewModel.timerModeEnabled {
                        Text(timerFormatted)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(timerIsLow ? WKColor.error : .primary)
                    }
                }
            }

            // Eye — shows/hides details panel; only active in feedback phase
            Button {
                showingDetails.toggle()
            } label: {
                Image(systemName: showingDetails ? "eye.fill" : "eye")
            }
            .disabled(viewModel.phase != .feedback)

            // Session history
            Button {
                showingHistory = true
            } label: {
                Image(systemName: "checkmark.circle")
            }
        }
    }

    // MARK: - Ready content

    @ViewBuilder
    private var readyContent: some View {
        // Subject card
        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(viewModel.prompt?.title ?? "")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(viewModel.remainingCount) left")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Text(viewModel.prompt?.subjectCharacters ?? "")
                    .font(.system(size: 48, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            }
        }

        // Answer / feedback card
        AppCard {
            if viewModel.phase == .answering {
                answeringInput
            } else {
                feedbackDisplay
            }
        }

        // Details panel — visible when eye is on and in feedback phase
        if showingDetails, let subject = viewModel.currentSubject {
            SubjectDetailsPanel(subject: subject)
        }

        // Action buttons
        actionButtons
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
                        targetScript: readingScript
                    )
                } else {
                    TextField(
                        viewModel.prompt?.placeholder ?? "Enter meaning",
                        text: $viewModel.userAnswer
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
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
                    case .reading: return viewModel.currentSubject?.primaryReading ?? "—"
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
                title: viewModel.isSubmitting ? "Submitting..." : "Submit"
            ) {
                Task { await viewModel.submitCurrentAnswer() }
            }
        } else {
            HStack(spacing: 12) {
                if viewModel.canUndo {
                    Button("← Undo") {
                        viewModel.undo()
                    }
                    .buttonStyle(.bordered)
                    .tint(WKColor.warning)
                }

                AppPrimaryButton(title: "Next →") {
                    Task { await viewModel.next() }
                }
            }
        }
    }
}

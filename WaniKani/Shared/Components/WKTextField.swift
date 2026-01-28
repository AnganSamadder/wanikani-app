import SwiftUI

// MARK: - WKTextField

/// A consistent text field component for user input.
public struct WKTextField: View {
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    let icon: String?
    let errorMessage: String?
    let onSubmit: (() -> Void)?
    
    @FocusState private var isFocused: Bool
    
    public init(
        _ placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        icon: String? = nil,
        errorMessage: String? = nil,
        onSubmit: (() -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.icon = icon
        self.errorMessage = errorMessage
        self.onSubmit = onSubmit
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: WKSpacing.xs) {
            HStack(spacing: WKSpacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(WKTypography.body)
                        .foregroundStyle(iconColor)
                        .frame(width: 20)
                }
                
                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(WKTypography.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFocused)
                .submitLabel(.go)
                .onSubmit {
                    onSubmit?()
                }
                
                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(WKTypography.body)
                            .foregroundStyle(WKColor.textTertiary)
                    }
                }
            }
            .padding(WKSpacing.md)
            .background(WKColor.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: WKRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: WKRadius.md, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: isFocused ? 2 : 0.5)
            )
            
            if let errorMessage = errorMessage {
                HStack(spacing: WKSpacing.xxs) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(errorMessage)
                }
                .font(WKTypography.caption)
                .foregroundStyle(WKColor.error)
            }
        }
    }
    
    private var iconColor: Color {
        if errorMessage != nil {
            return WKColor.error
        }
        return isFocused ? .accentColor : WKColor.textSecondary
    }
    
    private var borderColor: Color {
        if errorMessage != nil {
            return WKColor.error
        }
        return isFocused ? .accentColor : WKColor.border
    }
}

// MARK: - WKAnswerField

/// A specialized text field for review/quiz answers with immediate feedback styling.
public struct WKAnswerField: View {
    @Binding var text: String
    let questionType: QuestionType
    let feedback: AnswerFeedback?
    let onSubmit: () -> Void
    
    @FocusState private var isFocused: Bool
    
    public enum QuestionType {
        case meaning
        case reading
    }
    
    public enum AnswerFeedback: Equatable {
        case correct
        case incorrect
        case almostCorrect(hint: String)
    }
    
    public init(
        text: Binding<String>,
        questionType: QuestionType,
        feedback: AnswerFeedback? = nil,
        onSubmit: @escaping () -> Void
    ) {
        self._text = text
        self.questionType = questionType
        self.feedback = feedback
        self.onSubmit = onSubmit
    }
    
    public var body: some View {
        VStack(spacing: WKSpacing.xs) {
            TextField(promptText, text: $text)
                .font(WKTypography.titleMedium)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(questionType == .meaning ? .never : .never)
                .autocorrectionDisabled()
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit(onSubmit)
                .padding(WKSpacing.md)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: WKRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: WKRadius.md, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: 2)
                )
                .onAppear {
                    isFocused = true
                }
            
            if case .almostCorrect(let hint) = feedback {
                Text(hint)
                    .font(WKTypography.caption)
                    .foregroundStyle(WKColor.warning)
            }
        }
    }
    
    private var promptText: String {
        questionType == .meaning ? "Your answer" : "Reading"
    }
    
    private var backgroundColor: Color {
        switch feedback {
        case .correct:
            return WKColor.success.opacity(0.15)
        case .incorrect:
            return WKColor.error.opacity(0.15)
        case .almostCorrect:
            return WKColor.warning.opacity(0.15)
        case nil:
            return WKColor.surfaceSecondary
        }
    }
    
    private var borderColor: Color {
        switch feedback {
        case .correct:
            return WKColor.success
        case .incorrect:
            return WKColor.error
        case .almostCorrect:
            return WKColor.warning
        case nil:
            return questionType == .meaning ? WKColor.textSecondary : WKColor.radical
        }
    }
}

#Preview {
    VStack(spacing: WKSpacing.lg) {
        WKTextField(
            "Enter your API token",
            text: .constant(""),
            isSecure: true,
            icon: "key.fill"
        )
        
        WKTextField(
            "Email",
            text: .constant("user@example.com"),
            icon: "envelope.fill"
        )
        
        WKTextField(
            "Username",
            text: .constant("bad"),
            icon: "person.fill",
            errorMessage: "Username must be at least 4 characters"
        )
        
        Divider()
        
        WKAnswerField(
            text: .constant(""),
            questionType: .meaning,
            feedback: nil
        ) { }
        
        WKAnswerField(
            text: .constant("correct"),
            questionType: .meaning,
            feedback: .correct
        ) { }
        
        WKAnswerField(
            text: .constant("wrong"),
            questionType: .meaning,
            feedback: .incorrect
        ) { }
    }
    .padding()
}

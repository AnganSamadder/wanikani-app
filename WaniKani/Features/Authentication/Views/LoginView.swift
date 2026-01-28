import SwiftUI
import WaniKaniCore

struct LoginView: View {
    @State private var apiToken: String = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - Hero Section
                    VStack(spacing: WKSpacing.lg) {
                        Spacer()
                            .frame(height: geometry.size.height * 0.08)
                        
                        // Brand Icon
                        ZStack {
                            Circle()
                                .fill(WKColor.kanji.opacity(0.15))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "character.book.closed.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(WKColor.kanji)
                        }
                        
                        VStack(spacing: WKSpacing.xs) {
                            Text("Welcome to")
                                .font(WKTypography.body)
                                .foregroundStyle(WKColor.textSecondary)
                            
                            Text("WaniKani")
                                .font(WKTypography.displayLarge)
                                .foregroundStyle(WKColor.textPrimary)
                        }
                        
                        Text("Master Japanese kanji and vocabulary\nwith intelligent spaced repetition")
                            .font(WKTypography.body)
                            .foregroundStyle(WKColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, WKSpacing.xl)
                    
                    Spacer()
                        .frame(height: WKSpacing.xxxl)
                    
                    // MARK: - Login Form
                    VStack(spacing: WKSpacing.lg) {
                        VStack(alignment: .leading, spacing: WKSpacing.sm) {
                            Text("API Token")
                                .font(WKTypography.captionMedium)
                                .foregroundStyle(WKColor.textSecondary)
                            
                            HStack(spacing: WKSpacing.sm) {
                                Image(systemName: "key.fill")
                                    .font(WKTypography.body)
                                    .foregroundStyle(isFocused ? WKColor.kanji : WKColor.textSecondary)
                                    .frame(width: 20)
                                
                                SecureField("Paste your token here", text: $apiToken)
                                    .font(WKTypography.body)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .focused($isFocused)
                                    .submitLabel(.go)
                                    .onSubmit(performLogin)
                                
                                if !apiToken.isEmpty {
                                    Button {
                                        apiToken = ""
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
                                    .strokeBorder(
                                        errorMessage != nil ? WKColor.error : (isFocused ? WKColor.kanji : WKColor.border),
                                        lineWidth: isFocused || errorMessage != nil ? 2 : 0.5
                                    )
                            )
                            
                            if let error = errorMessage {
                                HStack(spacing: WKSpacing.xxs) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                    Text(error)
                                }
                                .font(WKTypography.caption)
                                .foregroundStyle(WKColor.error)
                            }
                        }
                        
                        WKButton(
                            isLoading ? "Verifying..." : "Continue",
                            icon: isLoading ? nil : "arrow.right",
                            style: .primary,
                            size: .large,
                            isFullWidth: true,
                            isLoading: isLoading
                        ) {
                            performLogin()
                        }
                        .disabled(!isValid)
                        
                        // Privacy Note
                        HStack(spacing: WKSpacing.xs) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundStyle(WKColor.success)
                            Text("Your token is stored securely on your device")
                                .foregroundStyle(WKColor.textTertiary)
                        }
                        .font(WKTypography.caption)
                    }
                    .padding(.horizontal, WKSpacing.xl)
                    
                    Spacer()
                        .frame(height: WKSpacing.xxl)
                    
                    // MARK: - Help Link
                    VStack(spacing: WKSpacing.sm) {
                        Text("Don't have a token?")
                            .font(WKTypography.body)
                            .foregroundStyle(WKColor.textSecondary)
                        
                        Link(destination: URL(string: "https://www.wanikani.com/settings/personal_access_tokens")!) {
                            HStack(spacing: WKSpacing.xs) {
                                Text("Get one from WaniKani")
                                    .fontWeight(.medium)
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                            }
                            .font(WKTypography.body)
                            .foregroundStyle(WKColor.kanji)
                        }
                    }
                    
                    Spacer()
                        .frame(minHeight: WKSpacing.xxxl)
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(WKColor.surfacePrimary)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }
    
    private var isValid: Bool {
        !apiToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }
    
    private func performLogin() {
        let cleanToken = apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanToken.isEmpty else {
            errorMessage = "Please enter your API token"
            return
        }
        
        // Basic validation - WaniKani tokens are UUIDs (36 chars with dashes)
        guard cleanToken.count >= 32 else {
            errorMessage = "Token appears too short. Please check and try again."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Simulate brief verification delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AuthenticationManager.shared.login(apiKey: cleanToken)
            isLoading = false
        }
    }
}

#Preview {
    LoginView()
}

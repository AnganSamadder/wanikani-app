import SwiftUI
import WaniKaniCore

struct AuthTokenView: View {
    @State private var token = ""
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    @StateObject private var authManager = AuthenticationManager.shared

    var body: some View {
        AppScreen(title: "Welcome", subtitle: "Connect your WaniKani account") {
            if authManager.isAuthenticated {
                AppSectionTitle(icon: "checkmark.shield.fill", text: "Current Session")
                AppCard {
                    Label("You are already signed in.", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.green)
                    if let maskedToken {
                        Text("Saved token: \(maskedToken)")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    Text("You can stay signed in, replace the token below, or sign out.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Sign Out", role: .destructive) {
                        authManager.logout()
                    }
                }
            }

            AppSectionTitle(icon: "lock.fill", text: authManager.isAuthenticated ? "Replace API Token" : "API Token")
            AppCard {
                Text("Enter your WaniKani API token")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("wk_xxxxxxxxx", text: $token)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .disabled(isSubmitting)
                    .keyboardDoneButton()
                    .padding(12)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                AppPrimaryButton(title: isSubmitting ? "Connecting..." : "Continue") {
                    submitToken()
                }
                .disabled(isSubmitting)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onSubmit {
            submitToken()
        }
    }

    private func submitToken() {
        let normalizedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedToken.isEmpty else {
            errorMessage = "Enter your API token to continue."
            return
        }

        isSubmitting = true
        errorMessage = nil
        authManager.login(apiKey: normalizedToken)
        isSubmitting = false
    }

    private var maskedToken: String? {
        guard let storedToken = authManager.apiToken, !storedToken.isEmpty else {
            return nil
        }
        guard storedToken.count > 8 else {
            return String(repeating: "*", count: storedToken.count)
        }

        let prefix = storedToken.prefix(4)
        let suffix = storedToken.suffix(4)
        return "\(prefix)****\(suffix)"
    }
}

import SwiftUI
import WaniKaniCore

struct LoginView: View {
    @State private var apiToken: String = ""
    @State private var errorMessage: String?
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "character.book.closed.fill") // WaniKani-esque icon
                        .font(.system(size: 80))
                        .foregroundStyle(Color.accentColor)
                    
                    Text("Welcome to WaniKani")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Enter your Personal Access Token to sync your progress.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Form Section
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Token")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fontWeight(.medium)
                        
                        SecureField("Paste your token here", text: $apiToken)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($isFocused)
                            .submitLabel(.go)
                            .onSubmit(performLogin)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(errorMessage != nil ? Color.red : Color.clear, lineWidth: 1)
                            )
                    }
                    
                    if let error = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(error)
                        }
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Button(action: performLogin) {
                        Text("Login")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isValid ? Color.accentColor : Color.gray.opacity(0.3))
                            .cornerRadius(12)
                    }
                    .disabled(!isValid)
                }
                .padding(.horizontal)
                
                // Help Link
                Link(destination: URL(string: "https://www.wanikani.com/settings/personal_access_tokens")!) {
                    HStack(spacing: 4) {
                        Text("Don't have a token?")
                        Text("Get one here")
                            .fontWeight(.semibold)
                            .underline()
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
                
                Spacer()
                Spacer()
            }
            .padding()
            .onAppear {
                isFocused = true
            }
        }
    }
    
    private var isValid: Bool {
        !apiToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func performLogin() {
        let cleanToken = apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanToken.isEmpty else {
            errorMessage = "Token cannot be empty."
            return
        }
        
        // In a real app, we might validate the format (e.g. 36 chars for UUID)
        // For now, we rely on the API to reject it if invalid, 
        // but since AuthenticationManager.login is synchronous and basic:
        AuthenticationManager.shared.login(apiKey: cleanToken)
        errorMessage = nil
    }
}

#Preview {
    LoginView()
}

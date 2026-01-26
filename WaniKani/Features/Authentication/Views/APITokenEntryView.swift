import SwiftUI
import WaniKaniCore

struct APITokenEntryView: View {
    @State private var token: String = ""
    @StateObject private var authManager = AuthenticationManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Enter API Token")
                .font(.title)
            
            TextField("Token", text: $token)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            Button("Login") {
                authManager.login(apiKey: token)
            }
            .buttonStyle(.borderedProminent)
            .disabled(token.isEmpty)
            
            Link("Get Token", destination: URL(string: "https://www.wanikani.com/settings/personal_access_tokens")!)
        }
        .padding()
    }
}

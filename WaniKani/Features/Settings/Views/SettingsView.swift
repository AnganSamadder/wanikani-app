import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel(persistence: .shared)
    
    var body: some View {
        Form {
            Section("Account") {
                Button("Sign Out", role: .destructive) {
                    viewModel.signOut()
                }
            }
            
            Section("Offline") {
                NavigationLink("Sync Status") {
                    OfflineSyncView(viewModel: viewModel)
                }
            }
            
            Section("App") {
                Toggle("Dark Mode", isOn: .constant(false)) // Bind to PreferencesManager
            }
        }
        .navigationTitle("Settings")
    }
}

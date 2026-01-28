import SwiftUI
import WaniKaniCore

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel(persistence: .shared)
    @ObservedObject private var themeController = ThemeController.shared
    
    var body: some View {
        List {
            // MARK: - Appearance Section
            Section {
                // Theme Mode Picker
                Picker(selection: $themeController.themeMode) {
                    ForEach(ThemeMode.allCases, id: \.self) { mode in
                        Label(mode.displayName, systemImage: mode.icon)
                            .tag(mode)
                    }
                } label: {
                    Label {
                        Text("Appearance")
                    } icon: {
                        Image(systemName: "paintbrush.fill")
                            .foregroundStyle(WKColor.vocabulary)
                    }
                }
            } footer: {
                Text("Choose how the app looks. System follows your device settings.")
            }
            
            // MARK: - Sync Section
            Section {
                NavigationLink {
                    OfflineSyncView(viewModel: viewModel)
                } label: {
                    HStack {
                        Label {
                            Text("Offline Sync")
                        } icon: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundStyle(WKColor.radical)
                        }
                        
                        Spacer()
                        
                        if let date = viewModel.lastSyncDate {
                            Text(date, style: .relative)
                                .font(WKTypography.caption)
                                .foregroundStyle(WKColor.textTertiary)
                        }
                    }
                }
                
                Button {
                    Task { await viewModel.syncNow() }
                } label: {
                    HStack {
                        Label {
                            Text("Sync Now")
                        } icon: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(Color.accentColor)
                        }
                        
                        Spacer()
                        
                        if viewModel.isSyncing {
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.isSyncing)
            } header: {
                Text("Data")
            } footer: {
                Text("Sync your progress for offline access.")
            }
            
            // MARK: - About Section
            Section {
                HStack {
                    Label {
                        Text("Version")
                    } icon: {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(WKColor.textTertiary)
                    }
                    
                    Spacer()
                    
                    Text("1.0.0")
                        .foregroundStyle(WKColor.textSecondary)
                }
                
                Link(destination: URL(string: "https://www.wanikani.com")!) {
                    Label {
                        Text("WaniKani Website")
                    } icon: {
                        Image(systemName: "globe")
                            .foregroundStyle(WKColor.kanji)
                    }
                }
                
                Link(destination: URL(string: "https://community.wanikani.com")!) {
                    Label {
                        Text("Community Forums")
                    } icon: {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .foregroundStyle(WKColor.vocabulary)
                    }
                }
            } header: {
                Text("About")
            }
            
            // MARK: - Account Section
            Section {
                Button(role: .destructive) {
                    viewModel.signOut()
                } label: {
                    Label {
                        Text("Sign Out")
                    } icon: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            } header: {
                Text("Account")
            } footer: {
                Text("You'll need to enter your API token again to sign back in.")
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}

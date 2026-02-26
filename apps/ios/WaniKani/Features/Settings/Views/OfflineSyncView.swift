import SwiftUI
import WaniKaniCore

struct OfflineSyncView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        List {
            // MARK: - Sync Status
            Section {
                // Last Sync
                HStack {
                    Label {
                        Text("Last Synced")
                    } icon: {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(WKColor.textTertiary)
                    }
                    
                    Spacer()
                    
                    if let date = viewModel.lastSyncDate {
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(WKColor.textSecondary)
                    } else {
                        Text("Never")
                            .foregroundStyle(WKColor.textTertiary)
                    }
                }
                
                // Sync Status Indicator
                HStack {
                    Label {
                        Text("Status")
                    } icon: {
                        Image(systemName: statusIcon)
                            .foregroundStyle(statusColor)
                    }
                    
                    Spacer()
                    
                    Text(statusText)
                        .foregroundStyle(statusColor)
                }
            } header: {
                Text("Sync Status")
            }
            
            // MARK: - Sync Action
            Section {
                Button {
                    Task { await viewModel.syncNow() }
                } label: {
                    HStack {
                        Spacer()
                        
                        if viewModel.isSyncing {
                            ProgressView()
                                .padding(.trailing, WKSpacing.xs)
                            Text("Syncing...")
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .padding(.trailing, WKSpacing.xs)
                            Text("Sync Now")
                        }
                        
                        Spacer()
                    }
                    .font(WKTypography.bodyMedium)
                }
                .disabled(viewModel.isSyncing)
            } footer: {
                VStack(alignment: .leading, spacing: WKSpacing.sm) {
                    Text("Syncing downloads your subjects and assignments so you can do reviews offline.")
                    
                    if viewModel.isSyncing {
                        HStack(spacing: WKSpacing.xs) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("This may take a few minutes...")
                                .font(WKTypography.caption)
                        }
                        .foregroundStyle(WKColor.textTertiary)
                    }
                }
            }
            
            // MARK: - Storage Info
            Section {
                HStack {
                    Label {
                        Text("Cached Data")
                    } icon: {
                        Image(systemName: "internaldrive.fill")
                            .foregroundStyle(WKColor.textTertiary)
                    }
                    
                    Spacer()
                    
                    Text("12.4 MB")
                        .foregroundStyle(WKColor.textSecondary)
                }
                
                Button(role: .destructive) {
                    // Clear cache action
                } label: {
                    Label {
                        Text("Clear Cache")
                    } icon: {
                        Image(systemName: "trash")
                    }
                }
            } header: {
                Text("Storage")
            } footer: {
                Text("Clearing the cache will remove downloaded data. You'll need to sync again for offline access.")
            }
        }
        .navigationTitle("Offline Sync")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var statusIcon: String {
        if viewModel.isSyncing {
            return "arrow.triangle.2.circlepath"
        } else if viewModel.lastSyncDate != nil {
            return "checkmark.circle.fill"
        } else {
            return "exclamationmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        if viewModel.isSyncing {
            return .accentColor
        } else if viewModel.lastSyncDate != nil {
            return WKColor.success
        } else {
            return WKColor.warning
        }
    }
    
    private var statusText: String {
        if viewModel.isSyncing {
            return "Syncing"
        } else if viewModel.lastSyncDate != nil {
            return "Up to date"
        } else {
            return "Not synced"
        }
    }
}

#Preview {
    NavigationStack {
        OfflineSyncView(viewModel: SettingsViewModel(persistence: .shared))
    }
}

import SwiftUI

struct OfflineSyncView: View {
    @ObservedObject var viewModel: NativeSettingsViewModel
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Last Synced")
                    Spacer()
                    if let date = viewModel.lastSyncDate {
                        Text(date.formatted())
                            .foregroundColor(.secondary)
                    } else {
                        Text("Never")
                            .foregroundColor(.secondary)
                    }
                }
                
                Button {
                    Task { await viewModel.syncNow() }
                } label: {
                    if viewModel.isSyncing {
                        ProgressView()
                    } else {
                        Text("Sync Now")
                    }
                }
                .disabled(viewModel.isSyncing)
            } footer: {
                Text("Syncing allows you to do reviews offline.")
            }
        }
        .navigationTitle("Offline Sync")
    }
}

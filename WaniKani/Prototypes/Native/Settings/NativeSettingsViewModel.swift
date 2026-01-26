import SwiftUI
import WaniKaniCore

@MainActor
class NativeSettingsViewModel: ObservableObject {
    @Published var lastSyncDate: Date?
    @Published var isSyncing = false
    
    private let preferences: PreferencesManager
    private let syncManager: SyncManager
    
    init(preferences: PreferencesManager = PreferencesManager()) {
        self.preferences = preferences
        // Stub SyncManager
        self.syncManager = SyncManager(api: WaniKaniAPI(networkClient: URLSessionNetworkClient(), apiToken: ""))
        self.lastSyncDate = preferences.lastSyncDate
    }
    
    func syncNow() async {
        isSyncing = true
        // try? await syncManager.syncEverything()
        try? await Task.sleep(nanoseconds: 2 * 1_000_000_000) // Fake sync
        preferences.lastSyncDate = Date()
        lastSyncDate = Date()
        isSyncing = false
    }
    
    func signOut() {
        // Clear token and reset state
    }
}

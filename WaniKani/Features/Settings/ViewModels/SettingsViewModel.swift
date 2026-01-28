import SwiftUI
import WaniKaniCore

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var lastSyncDate: Date?
    @Published var isSyncing = false
    @Published var syncProgress: SyncProgress?
    @Published var syncError: String?
    
    private let persistence: PersistenceManager
    private let preferences: PreferencesManager
    private var syncManager: SyncManager?
    
    init(persistence: PersistenceManager, preferences: PreferencesManager = PreferencesManager()) {
        self.persistence = persistence
        self.preferences = preferences
        self.lastSyncDate = preferences.lastSyncDate
        
        // Initialize sync manager with current API token
        updateSyncManager()
    }
    
    private func updateSyncManager() {
        guard let apiToken = AuthenticationManager.shared.apiToken, !apiToken.isEmpty else {
            syncManager = nil
            return
        }
        
        let api = WaniKaniAPI(networkClient: URLSessionNetworkClient(), apiToken: apiToken)
        syncManager = SyncManager(
            api: api,
            persistence: persistence,
            preferences: preferences
        )
    }
    
    func syncNow() async {
        guard let syncManager = syncManager else {
            syncError = "No API token configured"
            return
        }
        
        isSyncing = true
        syncError = nil
        syncProgress = .starting
        
        do {
            try await syncManager.syncEverything { [weak self] progress in
                Task { @MainActor in
                    self?.syncProgress = progress
                }
            }
            
            // Update last sync date from preferences (set by SyncManager)
            lastSyncDate = preferences.lastSyncDate
            syncProgress = .completed
        } catch {
            syncError = error.localizedDescription
            syncProgress = .failed(error.localizedDescription)
        }
        
        isSyncing = false
    }
    
    func signOut() {
        AuthenticationManager.shared.logout()
        syncManager = nil
    }
}

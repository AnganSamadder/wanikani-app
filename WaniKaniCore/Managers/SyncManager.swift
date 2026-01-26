import Foundation
import SwiftData

public actor SyncManager {
    private let api: WaniKaniAPI
    private let persistence: PersistenceManager
    private let preferences: PreferencesManager
    
    public init(
        api: WaniKaniAPI,
        persistence: PersistenceManager = .shared,
        preferences: PreferencesManager = PreferencesManager()
    ) {
        self.api = api
        self.persistence = persistence
        self.preferences = preferences
    }
    
    public func syncUser() async throws {
        let user = try await api.getUser()
        await MainActor.run {
            persistence.saveUser(user)
        }
        preferences.lastSyncDate = Date()
    }
    
    public func syncEverything() async throws {
        try await syncUser()
        // Expanded logic will be added in future tasks
        // Current focus is architecture
    }
}

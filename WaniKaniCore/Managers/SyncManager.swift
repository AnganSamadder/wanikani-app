import Foundation
import SwiftData

public actor SyncManager {
    private let api: WaniKaniAPI
    private let persistence: PersistenceManager
    private let preferences: PreferencesManager
    
    public init(
        api: WaniKaniAPI,
        persistence: PersistenceManager,
        preferences: PreferencesManager = PreferencesManager()
    ) {
        self.api = api
        self.persistence = persistence
        self.preferences = preferences
    }
    
    public func syncUser() async throws {
        SmartLogger.shared.info("Starting user sync")
        do {
            let user = try await api.getUser()
            await MainActor.run {
                persistence.saveUser(user)
            }
            preferences.lastSyncDate = Date()
            SmartLogger.shared.info("User sync completed")
        } catch {
            SmartLogger.shared.error("Failed to sync user: \(error.localizedDescription)")
            throw error
        }
    }
    
    public func syncSubjects() async throws {
        SmartLogger.shared.info("Starting subjects sync")
        do {
            let subjects = try await api.getAllSubjects()
            SmartLogger.shared.info("Fetched \(subjects.count) subjects, saving to persistence")
            await MainActor.run {
                persistence.saveSubjects(subjects)
            }
            SmartLogger.shared.info("Subjects sync completed")
        } catch {
            SmartLogger.shared.error("Failed to sync subjects: \(error.localizedDescription)")
            throw error
        }
    }
    
    public func syncAssignments() async throws {
        SmartLogger.shared.info("Starting assignments sync")
        do {
            let assignments = try await api.getAssignments()
            SmartLogger.shared.info("Fetched \(assignments.count) assignments, saving to persistence")
            await MainActor.run {
                persistence.saveAssignments(assignments)
            }
            SmartLogger.shared.info("Assignments sync completed")
        } catch {
            SmartLogger.shared.error("Failed to sync assignments: \(error.localizedDescription)")
            throw error
        }
    }
    
    public func syncEverything() async throws {
        SmartLogger.shared.info("Starting full sync")
        do {
            try await syncUser()
            try await syncSubjects()
            try await syncAssignments()
            SmartLogger.shared.info("Full sync completed")
        } catch {
            SmartLogger.shared.error("Full sync failed: \(error.localizedDescription)")
            throw error
        }
    }
}

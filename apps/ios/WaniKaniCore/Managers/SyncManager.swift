import Foundation
import SwiftData

public enum SyncProgress: Sendable {
    case starting
    case syncingUser
    case syncingSubjects(Int) // count fetched so far
    case syncingAssignments(Int) // count fetched so far
    case completed
    case failed(String)
}

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
        do {
            let user = try await api.getUser()
            await MainActor.run {
                persistence.saveUser(user)
            }
        } catch {
            SmartLogger.shared.error("User sync failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    public func syncSubjects(updatedAfter: Date? = nil, progress: ((SyncProgress) -> Void)? = nil) async throws {
        progress?(.syncingSubjects(0))
        do {
            let subjects = try await api.getAllSubjects(updatedAfter: updatedAfter)
            progress?(.syncingSubjects(subjects.count))
            await MainActor.run {
                persistence.saveSubjects(subjects)
            }
        } catch {
            SmartLogger.shared.error("Subjects sync failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    public func syncAssignments(updatedAfter: Date? = nil, progress: ((SyncProgress) -> Void)? = nil) async throws {
        progress?(.syncingAssignments(0))
        do {
            let assignments = try await api.getAssignments(updatedAfter: updatedAfter)
            progress?(.syncingAssignments(assignments.count))
            await MainActor.run {
                persistence.saveAssignments(assignments)
            }
        } catch {
            SmartLogger.shared.error("Assignments sync failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    public func syncEverything(progress: ((SyncProgress) -> Void)? = nil) async throws {
        progress?(.starting)
        
        let lastSyncDate = preferences.lastSyncDate
        
        do {
            progress?(.syncingUser)
            try await syncUser()
            
            progress?(.syncingSubjects(0))
            try await syncSubjects(updatedAfter: lastSyncDate, progress: progress)
            
            progress?(.syncingAssignments(0))
            try await syncAssignments(updatedAfter: lastSyncDate, progress: progress)
            
            // Update last sync date only after successful completion
            preferences.lastSyncDate = Date()
            
            progress?(.completed)
        } catch {
            let errorMessage = error.localizedDescription
            SmartLogger.shared.error("Sync failed: \(errorMessage)")
            progress?(.failed(errorMessage))
            throw error
        }
    }
}

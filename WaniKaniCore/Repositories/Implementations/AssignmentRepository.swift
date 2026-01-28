import Foundation

@MainActor
public final class AssignmentRepository: AssignmentRepositoryProtocol {
    private let persistenceManager: PersistenceManager
    
    public init(persistenceManager: PersistenceManager) {
        self.persistenceManager = persistenceManager
    }
    
    public func fetchAssignments(availableBefore: Date) async throws -> [PersistentAssignment] {
        persistenceManager.fetchAvailableAssignments(before: availableBefore)
    }
    
    public func fetchAssignment(id: Int) async throws -> PersistentAssignment? {
        persistenceManager.fetchAssignment(id: id)
    }
}

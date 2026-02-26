import Foundation

@MainActor
public final class AssignmentRepository: AssignmentRepositoryProtocol {
    private let persistenceManager: PersistenceManager
    
    public init(persistenceManager: PersistenceManager) {
        self.persistenceManager = persistenceManager
    }
    
    public func fetchAssignments(availableBefore: Date) async throws -> [AssignmentSnapshot] {
        persistenceManager.fetchAvailableAssignmentSnapshots(before: availableBefore)
    }
    
    public func fetchAssignment(id: Int) async throws -> AssignmentSnapshot? {
        persistenceManager.fetchAssignmentSnapshot(id: id)
    }
}

import Foundation

@MainActor
public final class SubjectRepository: SubjectRepositoryProtocol {
    private let persistenceManager: PersistenceManager
    
    public init(persistenceManager: PersistenceManager) {
        self.persistenceManager = persistenceManager
    }
    
    public func fetchSubject(id: Int) async throws -> SubjectSnapshot? {
        persistenceManager.fetchSubjectSnapshot(id: id)
    }
}

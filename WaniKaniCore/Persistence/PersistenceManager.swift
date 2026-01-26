import SwiftData
import Foundation

public final class PersistenceManager {
    public let container: ModelContainer
    public let context: ModelContext
    
    @MainActor
    public static let shared = PersistenceManager()
    
    public init(inMemory: Bool = false) {
        let schema = Schema([
            PersistentUser.self,
            PersistentSubject.self,
            PersistentMeaning.self,
            PersistentAssignment.self,
            PersistentReview.self
        ])
        
        let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        
        do {
            container = try ModelContainer(for: schema, configurations: config)
            context = ModelContext(container)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    public func save() throws {
        try context.save()
    }
    
    public func saveUser(_ user: User) {
        // Delete existing user if any
        try? context.delete(model: PersistentUser.self)
        let persistentUser = PersistentUser(from: user)
        context.insert(persistentUser)
        try? save()
    }
    
    public func fetchUser() -> User? {
        let descriptor = FetchDescriptor<PersistentUser>()
        let users = try? context.fetch(descriptor)
        return users?.first?.toDomain()
    }
}

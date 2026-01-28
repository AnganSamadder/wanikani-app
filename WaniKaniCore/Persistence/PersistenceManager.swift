import SwiftData
import Foundation

@MainActor
public final class PersistenceManager {
    public let container: ModelContainer
    public let context: ModelContext
    
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
    
    // MARK: - Subjects
    
    public func saveSubjects(_ subjects: [SubjectData]) {
        for subject in subjects {
            let persistentSubject = PersistentSubject(from: subject)
            context.insert(persistentSubject)
        }
        try? save()
    }
    
    public func fetchSubject(id: Int) -> PersistentSubject? {
        let descriptor = FetchDescriptor<PersistentSubject>(
            predicate: #Predicate<PersistentSubject> { $0.id == id }
        )
        let subjects = try? context.fetch(descriptor)
        return subjects?.first
    }
    
    // MARK: - Assignments
    
    public func saveAssignments(_ assignments: [Assignment]) {
        for assignment in assignments {
            let persistentAssignment = PersistentAssignment(from: assignment)
            context.insert(persistentAssignment)
        }
        try? save()
    }
    
    public func fetchAssignment(id: Int) -> PersistentAssignment? {
        let descriptor = FetchDescriptor<PersistentAssignment>(
            predicate: #Predicate<PersistentAssignment> { $0.id == id }
        )
        let assignments = try? context.fetch(descriptor)
        return assignments?.first
    }
    
    public func fetchAvailableAssignments(before date: Date) -> [PersistentAssignment] {
        let descriptor = FetchDescriptor<PersistentAssignment>(
            predicate: #Predicate<PersistentAssignment> { 
                if let availableAt = $0.availableAt {
                    return availableAt <= date
                } else {
                    return false
                }
            },
            sortBy: [SortDescriptor(\.availableAt)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}

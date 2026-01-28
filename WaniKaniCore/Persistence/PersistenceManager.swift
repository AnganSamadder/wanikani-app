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
        
        // Ensure Application Support directory exists for SwiftData
        if !inMemory {
            let fileManager = FileManager.default
            if let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
            }
        }
        
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
            upsertSubject(subject)
        }
        try? save()
    }
    
    private func upsertSubject(_ subject: SubjectData) {
        let subjectID = subject.id
        // Check if subject already exists
        let descriptor = FetchDescriptor<PersistentSubject>(
            predicate: #Predicate<PersistentSubject> { $0.id == subjectID }
        )
        if let existing = try? context.fetch(descriptor).first {
            // Delete and replace (SwiftData doesn't have a direct update, so delete + insert)
            context.delete(existing)
        }
        // Insert new
        let persistentSubject = PersistentSubject(from: subject)
        context.insert(persistentSubject)
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
            upsertAssignment(assignment)
        }
        try? save()
    }
    
    private func upsertAssignment(_ assignment: Assignment) {
        let assignmentID = assignment.id
        // Check if assignment already exists
        let descriptor = FetchDescriptor<PersistentAssignment>(
            predicate: #Predicate<PersistentAssignment> { $0.id == assignmentID }
        )
        if let existing = try? context.fetch(descriptor).first {
            // Update existing properties
            existing.subjectID = assignment.data.subjectID
            existing.subjectType = assignment.data.subjectType.rawValue
            existing.srsStage = assignment.data.srsStage
            existing.availableAt = assignment.data.availableAt
            existing.unlockedAt = assignment.data.unlockedAt
            existing.startedAt = assignment.data.startedAt
            existing.passedAt = assignment.data.passedAt
            existing.burnedAt = assignment.data.burnedAt
            existing.hidden = assignment.data.hidden
        } else {
            // Insert new
            let persistentAssignment = PersistentAssignment(from: assignment)
            context.insert(persistentAssignment)
        }
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
    
    // MARK: - Snapshot Conversions
    
    public func fetchSubjectSnapshot(id: Int) -> SubjectSnapshot? {
        guard let persistent = fetchSubject(id: id) else { return nil }
        return SubjectSnapshot(from: persistent)
    }
    
    public func fetchAssignmentSnapshot(id: Int) -> AssignmentSnapshot? {
        guard let persistent = fetchAssignment(id: id) else { return nil }
        return AssignmentSnapshot(from: persistent)
    }
    
    public func fetchAvailableAssignmentSnapshots(before date: Date) -> [AssignmentSnapshot] {
        let persistents = fetchAvailableAssignments(before: date)
        return persistents.map { AssignmentSnapshot(from: $0) }
    }
    
    public func fetchLessonAssignmentSnapshots(now: Date) -> [AssignmentSnapshot] {
        let descriptor = FetchDescriptor<PersistentAssignment>(
            predicate: #Predicate<PersistentAssignment> {
                $0.srsStage == 0 &&
                $0.startedAt == nil &&
                $0.unlockedAt != nil &&
                $0.hidden == false
            },
            sortBy: [SortDescriptor(\.unlockedAt)]
        )
        let persistents = (try? context.fetch(descriptor)) ?? []
        return persistents.map { AssignmentSnapshot(from: $0) }
    }
}

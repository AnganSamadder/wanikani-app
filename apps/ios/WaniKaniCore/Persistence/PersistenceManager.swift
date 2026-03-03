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
            PersistentReview.self,
            PersistentPendingReview.self,
            PersistentStudyMaterial.self,
            PersistentCompanionQueueItem.self
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
        guard !subjects.isEmpty else { return }

        // Fetch existing subjects once to avoid N per-subject fetches during large syncs.
        let existingSubjects = (try? context.fetch(FetchDescriptor<PersistentSubject>())) ?? []
        var existingByID: [Int: PersistentSubject] = [:]
        existingByID.reserveCapacity(existingSubjects.count)
        for existing in existingSubjects {
            existingByID[existing.id] = existing
        }

        for subject in subjects {
            if let existing = existingByID[subject.id] {
                context.delete(existing)
            }
            context.insert(PersistentSubject(from: subject))
        }
        try? save()
    }

    public func insertSubjects(_ subjects: [SubjectData]) {
        guard !subjects.isEmpty else { return }
        for subject in subjects {
            context.insert(PersistentSubject(from: subject))
        }
        try? save()
    }

    public func replaceAllSubjects(with subjects: [SubjectData]) {
        try? context.delete(model: PersistentSubject.self)
        insertSubjects(subjects)
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

    public func fetchSubjectSnapshots(ids: [Int]) -> [SubjectSnapshot] {
        let idSet = Set(ids)
        let descriptor = FetchDescriptor<PersistentSubject>()
        let persistents = (try? context.fetch(descriptor)) ?? []
        return persistents
            .filter { idSet.contains($0.id) }
            .map { SubjectSnapshot(from: $0) }
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

    // MARK: - Reviews

    public func saveReviews(_ reviews: [Review]) throws {
        for review in reviews {
            upsertReview(review)
        }
        try save()
    }

    private func upsertReview(_ review: Review) {
        let reviewID = review.id
        let descriptor = FetchDescriptor<PersistentReview>(
            predicate: #Predicate<PersistentReview> { $0.id == reviewID }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.createdAt = review.data.createdAt
            existing.incorrectMeaningAnswers = review.data.incorrectMeaningAnswers
            existing.incorrectReadingAnswers = review.data.incorrectReadingAnswers
        } else {
            let persistentReview = PersistentReview(from: review)
            context.insert(persistentReview)
        }
    }

    public func fetchDailyReviewCounts(from startDate: Date, to endDate: Date) -> [Date: Int] {
        let descriptor = FetchDescriptor<PersistentReview>()
        let reviews = (try? context.fetch(descriptor)) ?? []
        var counts: [Date: Int] = [:]
        let calendar = Calendar.current
        for review in reviews {
            guard let date = review.createdAt, date >= startDate, date <= endDate else { continue }
            let dayStart = calendar.startOfDay(for: date)
            counts[dayStart, default: 0] += 1
        }
        return counts
    }

    // MARK: - Pending Reviews

    public func upsertPendingReview(_ snapshot: PendingReviewSnapshot) throws {
        let assignmentID = snapshot.assignmentID
        let descriptor = FetchDescriptor<PersistentPendingReview>(
            predicate: #Predicate<PersistentPendingReview> { $0.assignmentID == assignmentID }
        )
        if let existing = try context.fetch(descriptor).first {
            existing.subjectID = snapshot.subjectID
            existing.subjectType = snapshot.subjectType
            existing.hasReadings = snapshot.hasReadings
            existing.meaningCompleted = snapshot.meaningCompleted
            existing.readingCompleted = snapshot.readingCompleted
            existing.incorrectMeaningAnswers = snapshot.incorrectMeaningAnswers
            existing.incorrectReadingAnswers = snapshot.incorrectReadingAnswers
            existing.updatedAt = snapshot.updatedAt
        } else {
            context.insert(PersistentPendingReview(
                assignmentID: snapshot.assignmentID,
                subjectID: snapshot.subjectID,
                subjectType: snapshot.subjectType,
                hasReadings: snapshot.hasReadings,
                meaningCompleted: snapshot.meaningCompleted,
                readingCompleted: snapshot.readingCompleted,
                incorrectMeaningAnswers: snapshot.incorrectMeaningAnswers,
                incorrectReadingAnswers: snapshot.incorrectReadingAnswers,
                updatedAt: snapshot.updatedAt
            ))
        }
        try save()
    }

    public func fetchPendingReviews() -> [PendingReviewSnapshot] {
        let descriptor = FetchDescriptor<PersistentPendingReview>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let persistents = (try? context.fetch(descriptor)) ?? []
        return persistents.map { PendingReviewSnapshot(from: $0) }
    }

    public func fetchPendingReview(assignmentID: Int) -> PendingReviewSnapshot? {
        let descriptor = FetchDescriptor<PersistentPendingReview>(
            predicate: #Predicate<PersistentPendingReview> { $0.assignmentID == assignmentID }
        )
        guard let persistent = try? context.fetch(descriptor).first else { return nil }
        return PendingReviewSnapshot(from: persistent)
    }

    public func deletePendingReview(assignmentID: Int) throws {
        let descriptor = FetchDescriptor<PersistentPendingReview>(
            predicate: #Predicate<PersistentPendingReview> { $0.assignmentID == assignmentID }
        )
        if let existing = try context.fetch(descriptor).first {
            context.delete(existing)
            try save()
        }
    }

    public func countHalfCompletions() -> Int {
        fetchPendingReviews().filter(\.isHalfComplete).count
    }

    public func prunePendingReviews(validAssignmentIDs: Set<Int>) throws {
        let descriptor = FetchDescriptor<PersistentPendingReview>()
        let persistents = (try? context.fetch(descriptor)) ?? []
        var mutated = false
        for pending in persistents where !validAssignmentIDs.contains(pending.assignmentID) {
            context.delete(pending)
            mutated = true
        }
        if mutated {
            try save()
        }
    }

    // MARK: - Active Queue

    public func upsertActiveQueueItem(assignmentID: Int, subjectID: Int,
                                       subjectType: String, questionType: String) throws {
        let itemID = "\(assignmentID)-\(questionType)"
        let descriptor = FetchDescriptor<PersistentCompanionQueueItem>(
            predicate: #Predicate<PersistentCompanionQueueItem> { $0.id == itemID }
        )
        if try context.fetch(descriptor).first != nil {
            // Already exists; nothing to update (addedAt stays from original insert)
        } else {
            context.insert(PersistentCompanionQueueItem(
                assignmentID: assignmentID,
                subjectID: subjectID,
                subjectType: subjectType,
                questionType: questionType
            ))
        }
        try save()
    }

    public func fetchActiveQueueItems() -> [ActiveQueueItemSnapshot] {
        let descriptor = FetchDescriptor<PersistentCompanionQueueItem>(
            sortBy: [SortDescriptor(\.addedAt)]
        )
        let persistents = (try? context.fetch(descriptor)) ?? []
        return persistents.map { ActiveQueueItemSnapshot(from: $0) }
    }

    public func deleteActiveQueueItem(assignmentID: Int, questionType: String) throws {
        let itemID = "\(assignmentID)-\(questionType)"
        let descriptor = FetchDescriptor<PersistentCompanionQueueItem>(
            predicate: #Predicate<PersistentCompanionQueueItem> { $0.id == itemID }
        )
        if let existing = try context.fetch(descriptor).first {
            context.delete(existing)
            try save()
        }
    }

    public func clearActiveQueue() throws {
        let descriptor = FetchDescriptor<PersistentCompanionQueueItem>()
        let all = (try? context.fetch(descriptor)) ?? []
        for item in all {
            context.delete(item)
        }
        if !all.isEmpty {
            try save()
        }
    }

    public func pruneActiveQueue(validAssignmentIDs: Set<Int>) throws {
        let descriptor = FetchDescriptor<PersistentCompanionQueueItem>()
        let persistents = (try? context.fetch(descriptor)) ?? []
        var mutated = false
        for item in persistents where !validAssignmentIDs.contains(item.assignmentID) {
            context.delete(item)
            mutated = true
        }
        if mutated {
            try save()
        }
    }

    // MARK: - Study Materials

    public func saveStudyMaterials(_ materials: [StudyMaterial]) throws {
        for material in materials {
            upsertStudyMaterial(material)
        }
        try save()
    }

    public func saveStudyMaterialSnapshot(_ snapshot: StudyMaterialSnapshot) throws {
        let subjectID = snapshot.subjectID
        let descriptor = FetchDescriptor<PersistentStudyMaterial>(
            predicate: #Predicate<PersistentStudyMaterial> { $0.subjectID == subjectID }
        )
        if let existing = try context.fetch(descriptor).first {
            existing.meaningNote = snapshot.meaningNote
            existing.readingNote = snapshot.readingNote
            existing.meaningSynonyms = snapshot.meaningSynonyms
            existing.updatedAt = snapshot.updatedAt
        } else {
            context.insert(PersistentStudyMaterial(
                subjectID: snapshot.subjectID,
                meaningNote: snapshot.meaningNote,
                readingNote: snapshot.readingNote,
                meaningSynonyms: snapshot.meaningSynonyms,
                updatedAt: snapshot.updatedAt
            ))
        }
        try save()
    }

    private func upsertStudyMaterial(_ studyMaterial: StudyMaterial) {
        let subjectID = studyMaterial.data.subjectID
        let descriptor = FetchDescriptor<PersistentStudyMaterial>(
            predicate: #Predicate<PersistentStudyMaterial> { $0.subjectID == subjectID }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.meaningNote = studyMaterial.data.meaningNote
            existing.readingNote = studyMaterial.data.readingNote
            existing.meaningSynonyms = studyMaterial.data.meaningSynonyms
            existing.updatedAt = studyMaterial.dataUpdatedAt ?? Date()
        } else {
            context.insert(PersistentStudyMaterial(from: studyMaterial))
        }
    }

    public func fetchStudyMaterial(subjectID: Int) -> StudyMaterialSnapshot? {
        let descriptor = FetchDescriptor<PersistentStudyMaterial>(
            predicate: #Predicate<PersistentStudyMaterial> { $0.subjectID == subjectID }
        )
        guard let persistent = try? context.fetch(descriptor).first else { return nil }
        return StudyMaterialSnapshot(from: persistent)
    }

    public func fetchStudyMaterials(subjectIDs: [Int]? = nil) -> [StudyMaterialSnapshot] {
        let descriptor = FetchDescriptor<PersistentStudyMaterial>()
        let persistents = (try? context.fetch(descriptor)) ?? []
        guard let subjectIDs, !subjectIDs.isEmpty else {
            return persistents.map { StudyMaterialSnapshot(from: $0) }
        }
        let set = Set(subjectIDs)
        return persistents
            .filter { set.contains($0.subjectID) }
            .map { StudyMaterialSnapshot(from: $0) }
    }
}

import Foundation

/// Protocol defining the interface for fetching summary data.
public protocol SummaryRepositoryProtocol: Sendable {
    /// Fetches the current summary of lessons and reviews.
    /// - Returns: A `Summary` object containing the latest statistics.
    func fetchSummary() async throws -> Summary
}

/// Protocol defining the interface for fetching subject data.
public protocol SubjectRepositoryProtocol: Sendable {
    /// Fetches a specific subject by its ID.
    /// - Parameter id: The unique identifier of the subject.
    /// - Returns: A `SubjectSnapshot` if found, otherwise `nil`.
    func fetchSubject(id: Int) async throws -> SubjectSnapshot?
}

/// Protocol defining the interface for managing assignment data.
public protocol AssignmentRepositoryProtocol: Sendable {
    /// Fetches assignments that are available before a specific date.
    /// - Parameter availableBefore: The cutoff date for available assignments.
    /// - Returns: An array of `AssignmentSnapshot` objects.
    func fetchAssignments(availableBefore: Date) async throws -> [AssignmentSnapshot]
    
    /// Fetches a specific assignment by its ID.
    /// - Parameter id: The unique identifier of the assignment.
    /// - Returns: An `AssignmentSnapshot` if found, otherwise `nil`.
    func fetchAssignment(id: Int) async throws -> AssignmentSnapshot?
}

/// Protocol defining the interface for submitting reviews.
public protocol ReviewRepositoryProtocol: Sendable {
    /// Submits a review for a specific assignment.
    /// - Parameters:
    ///   - assignmentId: The ID of the assignment being reviewed.
    ///   - incorrectMeaningAnswers: Number of incorrect meaning answers.
    ///   - incorrectReadingAnswers: Number of incorrect reading answers.
    /// - Returns: The resulting `Review` object from the API.
    func submitReview(
        assignmentId: Int,
        incorrectMeaningAnswers: Int,
        incorrectReadingAnswers: Int
    ) async throws -> Review
}

import Foundation

@MainActor
public final class ReviewRepository: ReviewRepositoryProtocol {
    private let api: WaniKaniAPI
    
    public init(api: WaniKaniAPI) {
        self.api = api
    }
    
    public func submitReview(
        assignmentId: Int,
        incorrectMeaningAnswers: Int,
        incorrectReadingAnswers: Int
    ) async throws -> Review {
        try await api.submitReview(
            assignmentID: assignmentId,
            incorrectMeaningAnswers: incorrectMeaningAnswers,
            incorrectReadingAnswers: incorrectReadingAnswers
        )
    }
}

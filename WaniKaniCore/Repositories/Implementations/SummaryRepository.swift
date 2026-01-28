import Foundation

@MainActor
public final class SummaryRepository: SummaryRepositoryProtocol {
    private let api: WaniKaniAPI
    
    public init(api: WaniKaniAPI) {
        self.api = api
    }
    
    public func fetchSummary() async throws -> Summary {
        try await api.getSummary()
    }
}

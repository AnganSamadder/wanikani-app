import SwiftUI
import WaniKaniCore

@MainActor
class StatisticsViewModel: ObservableObject {
    @Published var level: Int = 0
    @Published var accuracy: Double = 0.0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let persistence: PersistenceManager
    private let api: WaniKaniAPI
    private let logger = SmartLogger(subsystem: "com.angansamadder.wanikani", category: "Statistics")
    
    init(persistence: PersistenceManager) {
        self.persistence = persistence
        let apiToken = AuthenticationManager.shared.apiToken ?? ""
        self.api = WaniKaniAPI(networkClient: URLSessionNetworkClient(), apiToken: apiToken)
        
        Task {
            await loadStats()
        }
    }
    
    func loadStats() async {
        isLoading = true
        
        // Load user level from persistence
        if let user = persistence.fetchUser() {
            self.level = user.level
        }
        
        // Fetch review statistics to calculate accuracy
        do {
            let stats = try await api.getReviewStatistics()
            
            // Calculate overall accuracy
            let totalCorrect = stats.reduce(0) { $0 + $1.data.totalCorrect }
            let totalAnswers = stats.reduce(0) { $0 + $1.data.totalAnswers }
            
            if totalAnswers > 0 {
                self.accuracy = Double(totalCorrect) / Double(totalAnswers) * 100.0
            } else {
                self.accuracy = 0.0
            }
            
            logger.debug("Loaded statistics. Accuracy: \(self.accuracy)%")
            self.errorMessage = nil
        } catch {
            logger.error("Failed to load statistics: \(error.localizedDescription)")
            self.errorMessage = "Failed to load statistics"
            // Fallback to user's level only
            self.accuracy = 0.0
        }
        
        isLoading = false
    }
}

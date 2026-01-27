import SwiftUI
import WaniKaniCore

@MainActor
class StatisticsViewModel: ObservableObject {
    @Published var level: Int = 0
    @Published var accuracy: Double = 0.0
    
    private let persistence: PersistenceManager
    
    init(persistence: PersistenceManager) {
        self.persistence = persistence
        loadStats()
    }
    
    func loadStats() {
        if let user = persistence.fetchUser() {
            self.level = user.level
        }
        // Calculate accuracy from persistent reviews if available
        // For MVP stub:
        self.accuracy = 85.5
    }
}

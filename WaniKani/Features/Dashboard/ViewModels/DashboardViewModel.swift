import SwiftUI
import WaniKaniCore

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var user: User?
    @Published var summary: Summary?
    @Published var lessons: Int = 0
    @Published var reviews: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let persistence: PersistenceManager
    private let summaryRepository: SummaryRepositoryProtocol
    private let syncManager: SyncManager
    private let logger = SmartLogger(subsystem: "com.angansamadder.wanikani", category: "Dashboard")
    
    // Initializer injecting dependencies
    init(persistence: PersistenceManager, summaryRepository: SummaryRepositoryProtocol) {
        self.persistence = persistence
        self.summaryRepository = summaryRepository
        
        let apiToken = AuthenticationManager.shared.apiToken ?? ""
        self.syncManager = SyncManager(
            api: WaniKaniAPI(networkClient: URLSessionNetworkClient(), apiToken: apiToken),
            persistence: persistence
        )
        
        logger.debug("DashboardViewModel initialized")
        // Start initial load
        Task {
            await loadData()
        }
    }
    
    func loadData() async {
        isLoading = true
        
        // 1. Load User from Persistence
        if let pUser = persistence.fetchUser() {
            self.user = pUser
            logger.debug("Loaded user: \(pUser.username)")
        } else {
            logger.debug("No user in persistence")
        }
        
        // 2. Fetch Summary from Repository (API)
        do {
            let summary = try await summaryRepository.fetchSummary()
            self.summary = summary
            
            // Update counts using model's computed properties
            // Note: If model logic needs improvement (e.g. summing all past buckets), do it in Model or here.
            // For now trusting the model.
            self.lessons = summary.data.availableLessonsCount
            self.reviews = summary.data.availableReviewsCount
            
            logger.debug("Loaded summary. Lessons: \(self.lessons), Reviews: \(self.reviews)")
            self.errorMessage = nil
        } catch {
            logger.error("Failed to fetch summary: \(error.localizedDescription)")
            self.errorMessage = "Failed to load summary: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refresh() async {
        isLoading = true
        logger.info("Refreshing dashboard data...")
        
        do {
            // 1. Sync User (API -> Persistence)
            try await syncManager.syncUser()
            logger.info("User sync complete")
            
            // 2. Reload Data (Persistence -> UI, and Summary API -> UI)
            await loadData()
            
        } catch {
            logger.error("Refresh failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

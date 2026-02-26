import SwiftUI
import WaniKaniCore

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var user: User?
    @Published var summary: Summary?
    @Published var lessons: Int = 0
    @Published var reviews: Int = 0
    @Published var nextReviewsAt: Date?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var needsInitialSync = false
    
    private let persistence: PersistenceManager
    private let summaryRepository: SummaryRepositoryProtocol
    private let syncManager: SyncManager
    private let preferences: PreferencesManager
    private let logger = SmartLogger(subsystem: "com.angansamadder.wanikani", category: "Dashboard")
    
    // Initializer injecting dependencies
    init(persistence: PersistenceManager, summaryRepository: SummaryRepositoryProtocol, preferences: PreferencesManager = PreferencesManager()) {
        self.persistence = persistence
        self.summaryRepository = summaryRepository
        self.preferences = preferences
        
        let apiToken = AuthenticationManager.shared.apiToken ?? ""
        self.syncManager = SyncManager(
            api: WaniKaniAPI(networkClient: URLSessionNetworkClient(), apiToken: apiToken),
            persistence: persistence,
            preferences: preferences
        )
        
        // Check if initial sync is needed
        self.needsInitialSync = preferences.lastSyncDate == nil
        
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
        } else {
            // Auto-sync user if not present
            do {
                try await syncManager.syncUser()
                if let syncedUser = persistence.fetchUser() {
                    self.user = syncedUser
                }
            } catch {
                logger.error("Failed to sync user: \(error.localizedDescription)")
            }
        }
        
        // 2. Fetch Summary from Repository (API)
        do {
            let summary = try await summaryRepository.fetchSummary()
            self.summary = summary
            
            // Update counts using model's computed properties
            self.lessons = summary.data.availableLessonsCount
            self.reviews = summary.data.availableReviewsCount
            self.nextReviewsAt = summary.data.nextReviewsAt
            
            self.errorMessage = nil
        } catch {
            logger.error("Failed to fetch summary: \(error.localizedDescription)")
            self.errorMessage = "Failed to load summary: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refresh() async {
        isLoading = true
        
        do {
            // Perform full sync (user, subjects, assignments)
            try await syncManager.syncEverything { [weak self] progress in
                Task { @MainActor in
                    self?.needsInitialSync = false
                }
            }
            
            // Reload Data (Persistence -> UI, and Summary API -> UI)
            await loadData()
            
        } catch {
            logger.error("Refresh failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func performInitialSync() async {
        await refresh()
    }
}

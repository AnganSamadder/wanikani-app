import SwiftUI
import WaniKaniCore

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var user: User?
    @Published var summary: Summary?
    @Published var isLoading = false
    
    private let persistence: PersistenceManager
    private let syncManager: SyncManager
    private let logger = SmartLogger(subsystem: "com.angansamadder.wanikani", category: "Dashboard")
    
    // For MVP, we'll initialize SyncManager internally if not provided, 
    // but ideally it should be injected. For now we can assume shared/default.
    init(persistence: PersistenceManager) {
        self.persistence = persistence
        
        let apiToken = AuthenticationManager.shared.apiToken ?? ""
        self.syncManager = SyncManager(
            api: WaniKaniAPI(networkClient: URLSessionNetworkClient(), apiToken: apiToken),
            persistence: persistence
        ) 
        
        logger.debug("DashboardViewModel initialized with token length: \(apiToken.count)")
        loadData()
        
        // Auto-refresh if data is missing
        if user == nil && !apiToken.isEmpty {
            logger.info("User missing in persistence, triggering initial sync")
            Task {
                await refresh()
            }
        }
    }
    
    func loadData() {
        if let pUser = persistence.fetchUser() {
            self.user = pUser
            logger.debug("Loaded user from persistence: \(pUser.username)")
        } else {
            logger.debug("No user found in persistence")
        }
    }
    
    func refresh() async {
        isLoading = true
        logger.info("Starting dashboard refresh")
        do {
            try await syncManager.syncUser()
            logger.info("User sync completed successfully")
            loadData()
        } catch {
            logger.error("Refresh failed: \(error.localizedDescription)")
        }
        isLoading = false
    }
}

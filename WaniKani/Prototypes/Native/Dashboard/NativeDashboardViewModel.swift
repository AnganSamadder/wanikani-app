import SwiftUI
import WaniKaniCore

@MainActor
class NativeDashboardViewModel: ObservableObject {
    @Published var user: User?
    @Published var summary: Summary?
    @Published var isLoading = false
    
    private let persistence: PersistenceManager
    private let syncManager: SyncManager
    
    // For MVP, we'll initialize SyncManager internally if not provided, 
    // but ideally it should be injected. For now we can assume shared/default.
    init(persistence: PersistenceManager) {
        self.persistence = persistence
        // Stub sync manager for now until we have dependency injection or singleton
        // In real app, SyncManager should be shared
        self.syncManager = SyncManager(
            api: WaniKaniAPI(networkClient: URLSessionNetworkClient(), apiToken: ""),
            persistence: persistence
        ) 
        // Logic fix: SyncManager init requires API token which we don't have easily here.
        // Better: Fetch purely from persistence for now, trigger sync elsewhere.
        
        loadData()
    }
    
    func loadData() {
        if let pUser = persistence.fetchUser() {
            self.user = pUser
        }
        // Fetch summary from persistence if available (PersistentSummary not fully impl in 1.6 yet? Check PersistenceModels)
        // If not, leave nil
    }
    
    func refresh() async {
        isLoading = true
        // In future: await syncManager.syncEverything()
        // For now: reload from persistence
        loadData()
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000) // Fake delay
        isLoading = false
    }
}

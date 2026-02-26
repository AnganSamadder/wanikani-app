import Foundation
import WaniKaniCore

@MainActor
public class MarketplaceViewModel: ObservableObject {
    @Published public var scripts: [Script] = []
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    
    private let greasyForkAPI: GreasyForkAPI
    private let preferences: PreferencesManager
    
    // For MVP, we'll construct dependencies directly if not injected
    public init(greasyForkAPI: GreasyForkAPI? = nil, preferences: PreferencesManager = PreferencesManager()) {
        // Construct basic NetworkClient chain if not provided
        let network = URLSessionNetworkClient()
        self.greasyForkAPI = greasyForkAPI ?? GreasyForkAPI(networkClient: network)
        self.preferences = preferences
    }
    
    public func fetchScripts() async {
        isLoading = true
        errorMessage = nil
        do {
            scripts = try await greasyForkAPI.fetchScripts()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    public func isScriptEnabled(id: Int) -> Bool {
        preferences.enabledScriptIDs.contains(id)
    }
    
    public func toggleScript(id: Int) {
        var ids = preferences.enabledScriptIDs
        if ids.contains(id) {
            ids.removeAll { $0 == id }
        } else {
            ids.append(id)
        }
        preferences.enabledScriptIDs = ids
    }
}

import Foundation
import Combine

public class AuthenticationManager: ObservableObject {
    @Published public var isAuthenticated = false
    private let keychain = KeychainWrapper()
    private let sessionManager = SessionManager.shared
    private let logger = SmartLogger(subsystem: "com.angansamadder.wanikani", category: "Authentication")
    
    public static let shared = AuthenticationManager()
    
    private init() {
        checkLoginStatus()
    }
    
    func checkLoginStatus() {
        do {
            let _ = try keychain.retrieveString(forKey: "apiToken")
            isAuthenticated = true
            logger.info("Login status checked: Authenticated")
        } catch {
            isAuthenticated = false
            logger.info("Login status checked: Not Authenticated")
        }
    }
    
    public func login(apiKey: String) {
        try? keychain.save(apiKey, forKey: "apiToken")
        isAuthenticated = true
        logger.info("User logged in with API key")
    }
    
    public func logout() {
        try? keychain.delete(forKey: "apiToken")
        sessionManager.clearSession()
        isAuthenticated = false
        logger.info("User logged out")
    }
    
    public var apiToken: String? {
        try? keychain.retrieveString(forKey: "apiToken")
    }
}

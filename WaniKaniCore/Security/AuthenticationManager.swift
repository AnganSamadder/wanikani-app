import Foundation
import Combine

public class AuthenticationManager: ObservableObject {
    @Published public var isAuthenticated = false
    private let keychain = KeychainWrapper()
    private let sessionManager = SessionManager.shared
    
    public static let shared = AuthenticationManager()
    
    private init() {
        checkLoginStatus()
    }
    
    func checkLoginStatus() {
        do {
            let _ = try keychain.retrieveString(forKey: "apiToken")
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }
    }
    
    public func login(apiKey: String) {
        try? keychain.save(apiKey, forKey: "apiToken")
        isAuthenticated = true
    }
    
    public func logout() {
        try? keychain.delete(forKey: "apiToken")
        sessionManager.clearSession()
        isAuthenticated = false
    }
    
    public var apiToken: String? {
        try? keychain.retrieveString(forKey: "apiToken")
    }
}

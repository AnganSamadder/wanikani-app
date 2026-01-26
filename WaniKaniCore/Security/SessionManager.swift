import Foundation
import WebKit

public class SessionManager {
    public static let shared = SessionManager()
    
    private init() {}
    
    public func syncCookies(to webView: WKWebView, completion: @escaping () -> Void) {
        // Placeholder logic for MVP
        completion()
    }
    
    public func clearSession() {
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
            cookies.forEach { WKWebsiteDataStore.default().httpCookieStore.delete($0) }
        }
        
        NotificationCenter.default.post(name: .logoutRequest, object: nil)
    }
}

public extension Notification.Name {
    static let logoutRequest = Notification.Name("LogoutRequest")
}

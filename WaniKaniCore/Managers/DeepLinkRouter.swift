import Foundation

public enum DeepLink: Equatable {
    case dashboard
    case reviews
    case lessons
    case subject(id: Int)
    case level(number: Int)
    case settings
    case userScript(id: Int)
    case unknown(URL)
}

public final class DeepLinkRouter {
    
    public init() {}
    
    // MARK: - URL Parsing
    
    public func parse(url: URL) -> DeepLink {
        if url.scheme == "wanikani" {
            return parseCustomScheme(url: url)
        }
        
        if url.host == "www.wanikani.com" || url.host == "wanikani.com" {
            return parseUniversalLink(url: url)
        }
        
        return .unknown(url)
    }
    
    private func parseCustomScheme(url: URL) -> DeepLink {
        guard let host = url.host else {
            return .unknown(url)
        }
        
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        switch host {
        case "dashboard":
            return .dashboard
        case "reviews":
            return .reviews
        case "lessons":
            return .lessons
        case "subject":
            if let idString = pathComponents.first, let id = Int(idString) {
                return .subject(id: id)
            }
        case "level":
            if let numberString = pathComponents.first, let number = Int(numberString) {
                return .level(number: number)
            }
        case "settings":
            return .settings
        case "script":
            if let idString = pathComponents.first, let id = Int(idString) {
                return .userScript(id: id)
            }
        default:
            break
        }
        
        return .unknown(url)
    }
    
    private func parseUniversalLink(url: URL) -> DeepLink {
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        guard let first = pathComponents.first else {
            return .dashboard
        }
        
        switch first {
        case "dashboard":
            return .dashboard
        case "review":
            return .reviews
        case "lesson":
            return .lessons
        case "radicals", "kanji", "vocabulary":
            // /radicals/ground, /kanji/一, /vocabulary/一つ
            // For now, we'd need to look up the ID, so return unknown
            return .unknown(url)
        case "level":
            if pathComponents.count > 1, let number = Int(pathComponents[1]) {
                return .level(number: number)
            }
        case "settings":
            return .settings
        default:
            break
        }
        
        return .unknown(url)
    }
    
    // MARK: - URL Generation
    
    public func url(for deepLink: DeepLink) -> URL? {
        switch deepLink {
        case .dashboard:
            return URL(string: "wanikani://dashboard")
        case .reviews:
            return URL(string: "wanikani://reviews")
        case .lessons:
            return URL(string: "wanikani://lessons")
        case .subject(let id):
            return URL(string: "wanikani://subject/\(id)")
        case .level(let number):
            return URL(string: "wanikani://level/\(number)")
        case .settings:
            return URL(string: "wanikani://settings")
        case .userScript(let id):
            return URL(string: "wanikani://script/\(id)")
        case .unknown:
            return nil
        }
    }
}

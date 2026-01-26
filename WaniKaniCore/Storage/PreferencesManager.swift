import Foundation

public final class PreferencesManager {
    private let userDefaults: UserDefaults
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - Keys
    
    private enum Keys {
        static let darkModeEnabled = "darkModeEnabled"
        static let notificationsEnabled = "notificationsEnabled"
        static let lessonsBatchSize = "lessonsBatchSize"
        static let autoplayAudio = "autoplayAudio"
        static let enabledScriptIDs = "enabledScriptIDs"
        static let lastSyncDate = "lastSyncDate"
        static let selectedPrototypeMode = "selectedPrototypeMode"
    }
    
    // MARK: - Properties
    
    public var darkModeEnabled: Bool {
        get { userDefaults.bool(forKey: Keys.darkModeEnabled) }
        set { userDefaults.set(newValue, forKey: Keys.darkModeEnabled) }
    }
    
    public var notificationsEnabled: Bool {
        get { userDefaults.bool(forKey: Keys.notificationsEnabled) }
        set { userDefaults.set(newValue, forKey: Keys.notificationsEnabled) }
    }
    
    public var lessonsBatchSize: Int {
        get { 
            let value = userDefaults.integer(forKey: Keys.lessonsBatchSize)
            return value > 0 ? value : 5 // Default to 5
        }
        set { userDefaults.set(newValue, forKey: Keys.lessonsBatchSize) }
    }
    
    public var autoplayAudio: Bool {
        get { userDefaults.bool(forKey: Keys.autoplayAudio) }
        set { userDefaults.set(newValue, forKey: Keys.autoplayAudio) }
    }
    
    public var enabledScriptIDs: [Int] {
        get { userDefaults.array(forKey: Keys.enabledScriptIDs) as? [Int] ?? [] }
        set { userDefaults.set(newValue, forKey: Keys.enabledScriptIDs) }
    }
    
    public var lastSyncDate: Date? {
        get { userDefaults.object(forKey: Keys.lastSyncDate) as? Date }
        set { userDefaults.set(newValue, forKey: Keys.lastSyncDate) }
    }
    
    public var selectedPrototypeMode: String {
        get { userDefaults.string(forKey: Keys.selectedPrototypeMode) ?? "webview" }
        set { userDefaults.set(newValue, forKey: Keys.selectedPrototypeMode) }
    }
    
    // MARK: - Methods
    
    public func reset() {
        let keys = [
            Keys.darkModeEnabled,
            Keys.notificationsEnabled,
            Keys.lessonsBatchSize,
            Keys.autoplayAudio,
            Keys.enabledScriptIDs,
            Keys.lastSyncDate,
            Keys.selectedPrototypeMode
        ]
        keys.forEach { userDefaults.removeObject(forKey: $0) }
    }
}

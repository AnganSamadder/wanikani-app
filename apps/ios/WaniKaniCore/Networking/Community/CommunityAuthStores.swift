import Foundation

public actor DefaultCommunityAuthSessionStore: CommunityAuthSessionStore {
    private let keychain: KeychainWrapper
    private let tokenKey: String

    public init(
        keychain: KeychainWrapper = KeychainWrapper(service: "com.angansamadder.wanikani.community"),
        tokenKey: String = "community_api_token"
    ) {
        self.keychain = keychain
        self.tokenKey = tokenKey
    }

    public func currentAuthToken() async -> String? {
        try? keychain.retrieveString(forKey: tokenKey)
    }

    public func setAuthToken(_ token: String?) async {
        if let token, !token.isEmpty {
            try? keychain.save(token, forKey: tokenKey)
            return
        }
        try? keychain.delete(forKey: tokenKey)
    }
}

public actor InMemoryCommunityAuthSessionStore: CommunityAuthSessionStore {
    private var token: String?

    public init(token: String? = nil) {
        self.token = token
    }

    public func currentAuthToken() async -> String? {
        token
    }

    public func setAuthToken(_ token: String?) async {
        self.token = token
    }
}

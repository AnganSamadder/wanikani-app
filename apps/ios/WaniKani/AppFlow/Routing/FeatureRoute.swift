import Foundation

public enum FeatureRoute: Hashable, Sendable {
    case subjectDetail(id: Int)
    case reviewSession
    case lessonSession
    case settingsAccount
    case settingsTokens
    case settingsDangerZone
    case communityTopic(id: Int)
}

import Foundation

public enum SRSStage: Int, CaseIterable, Comparable {
    case initiate = 0
    case apprentice1 = 1
    case apprentice2 = 2
    case apprentice3 = 3
    case apprentice4 = 4
    case guru1 = 5
    case guru2 = 6
    case master = 7
    case enlightened = 8
    case burned = 9
    
    public static func < (lhs: SRSStage, rhs: SRSStage) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    public var name: String {
        switch self {
        case .initiate: return "Initiate"
        case .apprentice1, .apprentice2, .apprentice3, .apprentice4: return "Apprentice"
        case .guru1, .guru2: return "Guru"
        case .master: return "Master"
        case .enlightened: return "Enlightened"
        case .burned: return "Burned"
        }
    }
}

public struct SRSResult {
    public let newStage: SRSStage
    public let didLevelUp: Bool
    public let didLevelDown: Bool
}

public class SRSStateMachine {
    
    public init() {}
    
    public func calculateResult(currentStage: Int, incorrectAnswers: Int) -> SRSResult {
        let current = SRSStage(rawValue: currentStage) ?? .initiate
        var newStageRaw = current.rawValue
        
        if incorrectAnswers == 0 {
            newStageRaw += 1
        } else {
            if current.rawValue >= 5 {
                newStageRaw -= 2
            } else {
                newStageRaw -= 1
            }
            if newStageRaw < 1 { newStageRaw = 1 }
        }
        
        if newStageRaw > 9 { newStageRaw = 9 }
        
        let newStage = SRSStage(rawValue: newStageRaw) ?? .initiate
        
        return SRSResult(
            newStage: newStage,
            didLevelUp: newStage > current,
            didLevelDown: newStage < current
        )
    }
}

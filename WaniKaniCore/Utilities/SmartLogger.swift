import Foundation
import OSLog

public struct SmartLogger {
    private let logger: Logger
    
    public init(subsystem: String, category: String) {
        self.logger = Logger(subsystem: subsystem, category: category)
    }
    
    public static let shared = SmartLogger(subsystem: "com.angansamadder.wanikani", category: "General")
    
    public func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        log(level: .debug, message: message, file: file, function: function, line: line)
        #endif
    }
    
    public func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        log(level: .info, message: message, file: file, function: function, line: line)
        #endif
    }
    
    public func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        // Errors might be useful in production too, but respecting user request "shouldn't log anything in background"
        // We'll keep it strictly DEBUG for now as requested, or maybe allow errors?
        // User said: "when its actually published it shoudlnt log anything in the background"
        #if DEBUG
        log(level: .error, message: message, file: file, function: function, line: line)
        #endif
    }
    
    public func fault(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        log(level: .fault, message: message, file: file, function: function, line: line)
        #endif
    }
    
    private func log(level: OSLogType, message: String, file: String, function: String, line: Int) {
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) -> \(message)"
        logger.log(level: level, "\(logMessage, privacy: .public)")
    }
}

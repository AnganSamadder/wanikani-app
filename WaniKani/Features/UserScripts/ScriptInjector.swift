import WebKit
import Foundation
import WaniKaniCore

public class ScriptInjector: ObservableObject {
    private let preferences: PreferencesManager
    
    public init(preferences: PreferencesManager = PreferencesManager()) {
        self.preferences = preferences
    }
    
    public func createUserContentController() -> WKUserContentController {
        let controller = WKUserContentController()
        
        let enabledScripts = preferences.enabledScriptIDs
        
        for scriptID in enabledScripts {
            if let scriptContent = loadScriptContent(id: scriptID) {
                let injectionTime = determineInjectionTime(for: scriptContent)
                let userScript = WKUserScript(
                    source: scriptContent,
                    injectionTime: injectionTime,
                    forMainFrameOnly: false
                )
                controller.addUserScript(userScript)
            }
        }
        
        controller.add(ScriptMessageHandler(), name: "wanikaniApp")
        
        return controller
    }
    
    private func loadScriptContent(id: Int) -> String? {
        let fileManager = FileManager.default
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let scriptPath = documentsPath.appendingPathComponent("UserScripts/\(id).js")
        
        return try? String(contentsOf: scriptPath, encoding: .utf8)
    }
    
    private func determineInjectionTime(for scriptContent: String) -> WKUserScriptInjectionTime {
        if scriptContent.contains("@run-at document-start") {
            return .atDocumentStart
        }
        return .atDocumentEnd
    }
}

public class ScriptMessageHandler: NSObject, WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("[UserScript] Message: \(message.body)")
    }
}

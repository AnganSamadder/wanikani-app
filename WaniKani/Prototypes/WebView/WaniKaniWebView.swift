import SwiftUI
import WebKit

struct WaniKaniWebView: UIViewControllerRepresentable {
    let url: URL
    private let scriptInjector = ScriptInjector()
    private let cssInjector = CSSInjector()
    
    func makeUIViewController(context: Context) -> WebViewController {
        let vc = WebViewController()
        
        // Force view load to initialize webView
        let _ = vc.view
        
        // Access existing configuration's userContentController
        let existingController = vc.webView.configuration.userContentController
        
        // Create a controller from ScriptInjector to get the scripts
        let scriptController = scriptInjector.createUserContentController()
        
        // Copy user scripts
        for script in scriptController.userScripts {
            existingController.addUserScript(script)
        }
        
        // Add script message handler
        // Remove first in case it was already added (defensive)
        existingController.removeScriptMessageHandler(forName: "wanikaniApp")
        existingController.add(ScriptMessageHandler(), name: "wanikaniApp")
        
        // CSS Injection
        if let cssScript = cssInjector.createDarkModeScript() {
            existingController.addUserScript(cssScript)
        }
        
        vc.load(url: url)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: WebViewController, context: Context) {
        // Update logic
    }
}

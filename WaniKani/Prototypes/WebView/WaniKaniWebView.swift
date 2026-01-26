import SwiftUI
import WebKit

struct WaniKaniWebView: UIViewControllerRepresentable {
    let url: URL
    @StateObject private var scriptInjector = ScriptInjector()
    @StateObject private var cssInjector = CSSInjector()
    @StateObject private var offlineHandler = OfflineHandler()
    
    func makeUIViewController(context: Context) -> WebViewController {
        let vc = WebViewController()
        
        // Setup configuration with injectors
        let config = vc.webView.configuration
        let userContentController = scriptInjector.createUserContentController()
        
        if let cssScript = cssInjector.createDarkModeScript() {
            userContentController.addUserScript(cssScript)
        }
        
        config.userContentController = userContentController
        
        vc.delegate = context.coordinator
        
        vc.load(url: url)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: WebViewController, context: Context) {
        // Check offline status
        if !offlineHandler.isConnected {
            offlineHandler.injectOfflineBanner(webView: uiViewController.webView)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WebViewControllerDelegate {
        var parent: WaniKaniWebView
        
        init(_ parent: WaniKaniWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if !parent.offlineHandler.isConnected {
                parent.offlineHandler.injectOfflineBanner(webView: webView)
            }
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {}
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            if !parent.offlineHandler.isConnected {
                parent.offlineHandler.injectOfflineBanner(webView: webView)
            }
        }
    }
}

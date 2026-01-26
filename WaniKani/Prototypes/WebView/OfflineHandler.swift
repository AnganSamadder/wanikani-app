import Foundation
import Network
import WebKit

class OfflineHandler: ObservableObject {
    private let monitor = NWPathMonitor()
    @Published var isConnected = true
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
    
    func getOfflineHTML() -> String {
        """
        <html>
        <body style="font-family: -apple-system; text-align: center; padding: 20px; color: #333;">
            <h1>No Internet Connection</h1>
            <p>Please check your connection and try again.</p>
            <button onclick="window.location.reload()">Retry</button>
        </body>
        </html>
        """
    }
    
    func injectOfflineBanner(webView: WKWebView) {
        let js = """
        var banner = document.createElement('div');
        banner.innerHTML = 'You are offline';
        banner.style.position = 'fixed';
        banner.style.top = '0';
        banner.style.left = '0';
        banner.style.width = '100%';
        banner.style.backgroundColor = '#d9534f';
        banner.style.color = 'white';
        banner.style.textAlign = 'center';
        banner.style.padding = '10px';
        banner.style.zIndex = '9999';
        document.body.prepend(banner);
        """
        webView.evaluateJavaScript(js)
    }
}

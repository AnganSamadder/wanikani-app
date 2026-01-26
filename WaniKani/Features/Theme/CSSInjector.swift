import WebKit
import Foundation
import WaniKaniCore // For PreferencesManager

public class CSSInjector: ObservableObject {
    private let preferences: PreferencesManager
    
    public init(preferences: PreferencesManager = PreferencesManager()) {
        self.preferences = preferences
    }
    
    public func createDarkModeScript() -> WKUserScript? {
        guard preferences.darkModeEnabled else { return nil }
        
        let css = """
        :root {
            --color-bg: #1a1a1a;
            --color-text: #f0f0f0;
            --color-panel-bg: #2a2a2a;
            --color-border: #444;
        }
        
        body {
            background-color: var(--color-bg) !important;
            color: var(--color-text) !important;
        }
        
        /* Dashboard Panels */
        .dashboard-section, .review-status {
            background-color: var(--color-panel-bg) !important;
            border-color: var(--color-border) !important;
        }
        
        /* Navigation Bar */
        .navigation-bar {
            background-color: #000 !important;
            color: #888 !important;
        }
        
        /* Footer */
        footer {
            background-color: #000 !important;
            color: #888 !important;
        }
        
        /* Inputs */
        input, textarea {
            background-color: #333 !important;
            color: #fff !important;
            border: 1px solid #555 !important;
        }
        """
        
        // Remove newlines to make it a single line JS string
        let compactCSS = css.replacingOccurrences(of: "\n", with: " ")
        
        let source = """
        (function() {
            var style = document.createElement('style');
            style.type = 'text/css';
            style.innerHTML = '\(compactCSS)';
            document.head.appendChild(style);
        })();
        """
        
        return WKUserScript(
            source: source,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
    }
}

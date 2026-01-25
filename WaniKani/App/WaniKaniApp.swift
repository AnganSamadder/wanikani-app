//
//  WaniKaniApp.swift
//  WaniKani
//
//  Created by Angan Samadder on 1/25/26.
//

import SwiftUI

@main
struct WaniKaniApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            switch appState.prototypeMode {
            case .webview:
                WebViewRootView()
            case .native:
                NativeRootView()
            case .hybrid:
                HybridRootView()
            }
        }
    }
}

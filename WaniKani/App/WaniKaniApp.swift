//
//  WaniKaniApp.swift
//  WaniKani
//
//  Created by Angan Samadder on 1/25/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@main
struct WaniKaniApp: App {
    init() {
        #if canImport(UIKit)
        if ProcessInfo.processInfo.arguments.contains("-UITesting") {
            UIView.setAnimationsEnabled(false)
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

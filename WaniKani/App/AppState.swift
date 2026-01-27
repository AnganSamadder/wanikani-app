//
//  AppState.swift
//  WaniKani
//
//  Created by Angan Samadder on 1/25/26.
//

import SwiftUI

class AppState: ObservableObject {
    enum PrototypeMode: String {
        case webview, native, hybrid
    }
    
    var prototypeMode: PrototypeMode {
        // 1. Prefer Environment Variable (Xcode Scheme)
        if let mode = ProcessInfo.processInfo.environment["PROTOTYPE_MODE"],
           let proto = PrototypeMode(rawValue: mode) {
            return proto
        }
        
        // 2. Fallback to Bundle ID (Standalone App)
        let bundleID = Bundle.main.bundleIdentifier?.lowercased() ?? ""
        if bundleID.contains(".native") { return .native }
        if bundleID.contains(".hybrid") { return .hybrid }
        if bundleID.contains(".webview") { return .webview }
        
        // 3. Default
        return .webview
    }
}

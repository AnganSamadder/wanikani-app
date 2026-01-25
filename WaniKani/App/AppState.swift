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
        let mode = ProcessInfo.processInfo.environment["PROTOTYPE_MODE"] ?? "webview"
        return PrototypeMode(rawValue: mode) ?? .webview
    }
}

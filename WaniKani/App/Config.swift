//
//  Config.swift
//  WaniKani
//
//  Created by Angan Samadder on 1/25/26.
//

import Foundation

enum Config {
    static let apiBaseURL = URL(string: "https://api.wanikani.com/v2")!
    static let webBaseURL = URL(string: "https://www.wanikani.com")!
    
    enum Keys {
        static let apiToken = "WANIKANI_API_TOKEN"
    }
}

//
//  WebViewRootView.swift
//  WaniKani
//
//  Created by Angan Samadder on 1/25/26.
//

import SwiftUI

struct WebViewRootView: View {
    @State private var isLoading = false
    @State private var canGoBack = false
    @State private var canGoForward = false
    
    private let initialURL = URL(string: "https://www.wanikani.com/login")!
    
    var body: some View {
        NavigationStack {
            ZStack {
                WebViewContainer(
                    url: initialURL,
                    isLoading: $isLoading,
                    canGoBack: $canGoBack,
                    canGoForward: $canGoForward
                )
                .ignoresSafeArea(edges: .bottom)
                
                if isLoading {
                    ProgressView()
                        .controlSize(.large)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                }
            }
            .navigationTitle("WaniKani")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    WebViewRootView()
}

import SwiftUI
import WaniKaniCore

struct MarketplaceWebView: View {
    @StateObject private var viewModel = MarketplaceViewModel()
    
    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else {
                ForEach(viewModel.scripts) { script in
                    ScriptRow(script: script, isEnabled: viewModel.isScriptEnabled(id: script.id)) {
                        viewModel.toggleScript(id: script.id)
                    }
                }
            }
        }
        .navigationTitle("Script Marketplace")
        .task {
            await viewModel.fetchScripts()
        }
    }
}

struct ScriptRow: View {
    let script: Script
    let isEnabled: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(script.name)
                    .font(.headline)
                Text(script.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: onToggle) {
                Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isEnabled ? .green : .gray)
            }
        }
    }
}

import SwiftUI
import WaniKaniCore

struct NativeStatisticsView: View {
    @StateObject private var viewModel = NativeStatisticsViewModel(persistence: .shared)
    
    var body: some View {
        List {
            Section("Progress") {
                HStack {
                    Text("Level")
                    Spacer()
                    Text("\(viewModel.level)")
                }
                HStack {
                    Text("Accuracy")
                    Spacer()
                    Text(String(format: "%.1f%%", viewModel.accuracy))
                }
            }
            
            Section("Level Progression") {
                Text("Chart Placeholder")
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .navigationTitle("Statistics")
    }
}

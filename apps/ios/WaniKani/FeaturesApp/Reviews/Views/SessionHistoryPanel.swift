import SwiftUI

struct SessionHistoryPanel: View {
    let records: [ReviewSessionViewModel.ReviewAttemptRecord]

    var body: some View {
        NavigationStack {
            List {
                if records.isEmpty {
                    Text("No attempts yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(records.reversed()) { record in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.characters)
                                    .font(.headline)
                                Text("\(record.questionType.rawValue): \(record.userAnswer)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: record.wasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(record.wasCorrect ? WKColor.success : WKColor.error)
                        }
                    }
                }
            }
            .navigationTitle("Session History")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

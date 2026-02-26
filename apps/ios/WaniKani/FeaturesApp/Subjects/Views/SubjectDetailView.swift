import SwiftUI

struct SubjectDetailView: View {
    let subjectID: Int

    var body: some View {
        AppScreen(title: "部屋", subtitle: "Room") {
            AppSectionTitle(icon: "textformat.abc", text: "Kanji Composition")
            AppCard {
                Text("The vocabulary is composed of two kanji:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    AppTagPill(title: "部 Part", tint: WKColor.kanji)
                    AppTagPill(title: "屋 Roof", tint: WKColor.kanji)
                }
                Text("Subject ID: \(subjectID)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            AppCard {
                Text("Mnemonic")
                    .font(.headline.weight(.semibold))
                Text("Imagine each component to connect meaning, then infer reading before revealing the answer.")
                    .font(.body)
            }
            AppPrimaryButton(title: "Start Quiz") {}
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

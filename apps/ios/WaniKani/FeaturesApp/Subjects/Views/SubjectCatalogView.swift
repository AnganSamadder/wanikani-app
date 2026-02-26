import SwiftUI

struct SubjectCatalogView: View {
    var body: some View {
        AppScreen(title: "Subjects", subtitle: "Radicals, kanji, and vocabulary") {
            AppSectionTitle(icon: "books.vertical.fill", text: "Filters")
            HStack(spacing: 8) {
                AppTagPill(title: "Radicals", tint: WKColor.radical)
                AppTagPill(title: "Kanji", tint: WKColor.kanji)
                AppTagPill(title: "Vocabulary", tint: WKColor.vocabulary)
            }

            AppCard {
                Text("Level 1")
                    .font(.headline.weight(.semibold))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    subjectCell("⼌", subtitle: "Enter", tint: WKColor.radical)
                    subjectCell("工", subtitle: "Construction", tint: WKColor.radical)
                    subjectCell("大", subtitle: "Big", tint: WKColor.radical)
                    subjectCell("一", subtitle: "Ground", tint: WKColor.radical)
                    subjectCell("八", subtitle: "Fins", tint: WKColor.radical)
                    subjectCell("十", subtitle: "Cross", tint: WKColor.radical)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func subjectCell(_ symbol: String, subtitle: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            Text(symbol)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(tint)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(8)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

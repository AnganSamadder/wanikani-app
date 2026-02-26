import SwiftUI

struct SubjectSearchView: View {
    var body: some View {
        AppScreen(title: "Search", subtitle: "Find subjects quickly") {
            AppSectionTitle(icon: "magnifyingglass", text: "Query")
            AppCard {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    Text("Try: room, big, enter")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(12)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            AppCard {
                Text("Recent")
                    .font(.headline.weight(.semibold))
                Text("部屋 • へや")
                Text("大 • だい")
                Text("入る • はいる")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

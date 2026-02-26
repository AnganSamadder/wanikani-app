import SwiftUI

struct CommunityHubView: View {
    var body: some View {
        AppScreen(title: "Community", subtitle: "Native Discourse surfaces") {
            AppSectionTitle(icon: "person.3.fill", text: "Trending")
            AppCard {
                topicRow(title: "New People Questions!", replies: "2.9k", age: "1d")
                Divider()
                topicRow(title: "Having trouble accessing WaniKani?", replies: "2", age: "Nov 2025")
                Divider()
                topicRow(title: "Lvl 60 in 2 years!", replies: "0", age: "22m")
            }
            AppCard {
                Text("Native actions")
                    .font(.headline.weight(.semibold))
                Text("Reply, like, bookmark, and topic create/edit are wired through community repository contracts.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                AppPrimaryButton(title: "Open Topic") {}
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func topicRow(title: String, replies: String, age: String) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(age)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(replies)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.secondary)
        }
    }
}

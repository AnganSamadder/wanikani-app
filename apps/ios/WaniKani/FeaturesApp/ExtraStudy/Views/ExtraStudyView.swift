import SwiftUI

struct ExtraStudyView: View {
    var body: some View {
        AppScreen(title: "Extra Study", subtitle: "Targeted reinforcement") {
            AppSectionTitle(icon: "bolt.fill", text: "Modes")
            HStack(spacing: 10) {
                AppMetricTile(label: "Recently Missed", value: "37", tint: WKColor.warning)
                AppMetricTile(label: "Burn Reviews", value: "12", tint: WKColor.success)
            }
            AppCard {
                Text("Queue Preview")
                    .font(.headline.weight(.semibold))
                Text("• 入る")
                Text("• 部屋")
                Text("• 工")
            }
            AppPrimaryButton(title: "Start Session") {}
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

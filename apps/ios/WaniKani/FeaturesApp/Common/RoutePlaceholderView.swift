import SwiftUI

struct RoutePlaceholderView: View {
    let title: String
    let subtitle: String
    let sectionTitle: String

    var body: some View {
        AppScreen(title: title, subtitle: "parity scaffold") {
            AppSectionTitle(icon: "sparkles", text: sectionTitle)
            VStack(spacing: AppTheme.spacing) {
                PlaceholderCard(title: title, subtitle: subtitle)
                PlaceholderCard(
                    title: "Next Implementation Slice",
                    subtitle: "Replace this scaffold with API-backed ViewModel + repository wiring."
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

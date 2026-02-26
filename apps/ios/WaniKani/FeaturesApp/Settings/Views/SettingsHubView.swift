import SwiftUI
import WaniKaniCore

struct SettingsHubView: View {
    @AppStorage("undoButtonEnabled") private var undoButtonEnabled: Bool = true

    var body: some View {
        AppScreen(title: "Settings", subtitle: "App and account controls") {
            AppSectionTitle(icon: "gearshape.fill", text: "Configuration")
            AppSectionTitle(icon: "square.grid.2x2.fill", text: "Feature Routes")
            AppCard {
                NavigationLink("Subjects") { SubjectCatalogView() }
                NavigationLink("Search") { SubjectSearchView() }
                NavigationLink("Extra Study") { ExtraStudyView() }
                NavigationLink("Community") { CommunityHubView() }
                NavigationLink("Authentication") { AuthTokenView() }
                NavigationLink("Onboarding") { OnboardingFlowView() }
            }

            AppSectionTitle(icon: "checkmark.circle.fill", text: "Reviews")
            AppCard {
                Toggle(isOn: $undoButtonEnabled) {
                    Label("Undo Button", systemImage: "arrow.uturn.backward.circle")
                }
            }

            AppCard {
                Text("Settings sections (App/Account/Tokens/Danger Zone) are scaffolded for full implementation.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            AppCard {
                Text("Attributions")
                    .font(.headline.weight(.semibold))
                ForEach(LinguisticEnrichmentManager.attributionEntries, id: \.self) { entry in
                    Text(entry)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

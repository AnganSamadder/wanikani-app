import SwiftUI

struct SettingsHubView: View {
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

            AppCard {
                Text("Settings sections (App/Account/Tokens/Danger Zone) are scaffolded for full implementation.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

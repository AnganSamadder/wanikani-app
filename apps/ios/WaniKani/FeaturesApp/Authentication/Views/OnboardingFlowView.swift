import SwiftUI

struct OnboardingFlowView: View {
    var body: some View {
        AppScreen(title: "Learn Faster", subtitle: "Set up your study rhythm") {
            AppSectionTitle(icon: "sparkles", text: "Onboarding")
            AppCard {
                Text("1. Choose review cadence")
                Text("2. Enable notifications")
                Text("3. Configure dark mode and typography")
            }
            AppPrimaryButton(title: "Start Learning") {}
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

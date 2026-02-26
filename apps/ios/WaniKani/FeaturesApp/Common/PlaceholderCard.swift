import SwiftUI

struct PlaceholderCard: View {
    let title: String
    let subtitle: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        AppCard {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
        }
    }
}

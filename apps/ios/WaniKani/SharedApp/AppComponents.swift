import SwiftUI

struct AppScreen<Content: View>: View {
    let title: String
    let subtitle: String?
    let headerTint: Color?
    let headerTrailingText: String?
    @ViewBuilder let content: () -> Content
    @Environment(\.colorScheme) private var colorScheme

    init(
        title: String,
        subtitle: String? = nil,
        headerTint: Color? = nil,
        headerTrailingText: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.headerTint = headerTint
        self.headerTrailingText = headerTrailingText
        self.content = content
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.spacing) {
                AppHeroHeader(
                    title: title,
                    subtitle: subtitle,
                    tint: headerTint,
                    trailingText: headerTrailingText
                )
                content()
            }
            .padding(AppTheme.screenPadding)
        }
        .background(AppTheme.screenBackground(for: colorScheme).ignoresSafeArea())
    }
}

struct AppHeroHeader: View {
    let title: String
    let subtitle: String?
    let tint: Color?
    let trailingText: String?

    private var backgroundGradient: LinearGradient {
        if let tint {
            return LinearGradient(
                colors: [tint.opacity(0.96), tint.opacity(0.82)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return AppTheme.topGradient
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Text(title)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                Spacer(minLength: 0)
                if let trailingText, !trailingText.isEmpty {
                    Text(trailingText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.95))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.16))
                        .clipShape(Capsule())
                }
            }
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.88))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(backgroundGradient)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
    }
}

struct AppCard<Content: View>: View {
    @ViewBuilder let content: () -> Content
    @Environment(\.colorScheme) private var colorScheme

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.cardBackground(for: colorScheme))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .stroke(AppTheme.cardBorder(for: colorScheme), lineWidth: AppTheme.strokeWidth)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
    }
}

struct AppSectionTitle: View {
    let icon: String
    let text: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
            Text(text.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
        }
    }
}

struct AppMetricTile: View {
    let label: String
    let value: String
    let tint: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(tint.opacity(colorScheme == .dark ? 0.16 : 0.08))
        .clipShape(RoundedRectangle(cornerRadius: max(8, AppTheme.cardRadius - 4), style: .continuous))
    }
}

struct AppPrimaryButton: View {
    let title: String
    let tint: Color
    let action: () -> Void

    init(title: String, tint: Color = AppTheme.accent, action: @escaping () -> Void) {
        self.title = title
        self.tint = tint
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(.white)
                .background(tint)
                .clipShape(RoundedRectangle(cornerRadius: max(10, AppTheme.cardRadius), style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct AppTagPill: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(tint)
            .background(tint.opacity(0.14))
            .clipShape(Capsule())
    }
}

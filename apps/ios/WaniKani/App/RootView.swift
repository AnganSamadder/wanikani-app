import SwiftUI
import WaniKaniCore

struct RootView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var themeController = ThemeController.shared
    @State private var bootstrapState: BootstrapState = .idle

    private enum BootstrapState: Equatable {
        case idle
        case syncing(String)
        case ready
        case failed(String)
    }

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                authenticatedRoot
            } else {
                NavigationStack {
                    AuthTokenView()
                }
            }
        }
        .preferredColorScheme(themeController.preferredColorScheme)
        .task(id: authManager.isAuthenticated) {
            if authManager.isAuthenticated {
                await bootstrapIfNeeded()
            } else {
                bootstrapState = .idle
            }
        }
    }

    @ViewBuilder
    private var authenticatedRoot: some View {
        switch bootstrapState {
        case .ready:
            RootAppFlowView()
        case .idle, .syncing:
            NavigationStack {
                AppScreen(title: "Preparing Your Data", subtitle: "Syncing WaniKani content") {
                    AppCard {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(syncStatusText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
            }
        case .failed(let message):
            NavigationStack {
                AppScreen(title: "Sync Failed", subtitle: "Couldn’t prepare your study data") {
                    AppCard {
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        AppPrimaryButton(title: "Retry Sync") {
                            Task {
                                await bootstrapIfNeeded(force: true)
                            }
                        }
                        AppPrimaryButton(title: "Continue with Cached Data") {
                            bootstrapState = .ready
                        }
                        AppPrimaryButton(title: "Sign Out") {
                            authManager.logout()
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private var syncStatusText: String {
        if case .syncing(let message) = bootstrapState {
            return message
        }
        return "Starting sync..."
    }

    @MainActor
    private func bootstrapIfNeeded(force: Bool = false) async {
        if case .syncing = bootstrapState {
            return
        }
        if !force, case .ready = bootstrapState {
            return
        }

        guard let apiToken = authManager.apiToken, !apiToken.isEmpty else {
            bootstrapState = .failed("Missing API token. Please sign in again.")
            return
        }

        bootstrapState = .syncing("Starting sync...")

        let syncManager = SyncManager(
            api: WaniKaniAPI(
                networkClient: URLSessionNetworkClient(),
                apiToken: apiToken
            ),
            persistence: PersistenceManager.shared
        )

        do {
            try await syncManager.syncEverything { progress in
                let progressText: String
                switch progress {
                case .starting:
                    progressText = "Starting sync..."
                case .syncingUser:
                    progressText = "Syncing user profile..."
                case .syncingSubjects(let count):
                    progressText = "Syncing subjects (\(count))..."
                case .syncingAssignments(let count):
                    progressText = "Syncing assignments (\(count))..."
                case .completed:
                    progressText = "Completed."
                case .failed(let message):
                    progressText = "Failed: \(message)"
                }

                Task { @MainActor in
                    bootstrapState = .syncing(progressText)
                }
            }
            bootstrapState = .ready
        } catch {
            bootstrapState = .failed(error.localizedDescription)
        }
    }
}

# WaniKani iOS - Professional Source of Truth

This documentation is the **primary source of truth** for all AI agents and human developers working on the WaniKani iOS project. It defines the architecture, build system, coding conventions, and workflow expectations. All contributions must adhere to these standards.

## 1. Project Philosophy & Overview

The WaniKani iOS app is a high-performance, native SwiftUI application designed to provide the best possible user experience for WaniKani learners. After a comprehensive evaluation of various architectural approaches, the project has transitioned to a **100% Native SwiftUI** implementation utilizing WaniKani API v2.

### Core Objectives:
- **Performance**: Zero-latency navigation and smooth animations.
- **Reliability**: Robust offline support and predictable state management.
- **Scalability**: A feature-modular architecture that allows for independent development.
- **Modernity**: Leveraging Swift 6 features and strict concurrency checking.

---

## 2. Quick Start & Tooling

We use `xcodegen` to manage the Xcode project. **Never** modify `.xcodeproj` files directly; they are transient and can be regenerated at any time.

### Essential Commands (via Makefile)

| Command | Action |
|---------|--------|
| `make generate` | Regenerates the Xcode project using `xcodegen`. Run this after adding/removing files. |
| `make build` | Compiles the `WaniKani` scheme for the iPhone 16 simulator. |
| `make test` | Runs all unit and UI tests. |
| `make open` | Opens the generated project in Xcode. |
| `make clean` | Cleans build artifacts and removes the generated `.xcodeproj`. |

---

## 3. Project Structure

The codebase is organized into logical modules to promote separation of concerns and maintainability.

### `WaniKani/` (Application Layer)
- **`App/`**: Contains the application entry point (`WaniKaniApp.swift`), root navigation logic, and high-level configuration.
- **`Features/`**: Feature-specific modules (e.g., `Dashboard`, `Lessons`, `Reviews`). Each feature folder should contain its own `Views` and `ViewModels`.
- **`Shared/`**: UI components, extensions, and theme definitions shared across the application layer.

### `WaniKaniCore/` (Business Logic Layer)
This is a shared framework containing the "brains" of the application.
- **`Networking/`**: API clients, endpoint definitions, and network error handling.
- **`Models/`**: Codable entities representing WaniKani API resources.
- **`Persistence/`**: Data storage logic (e.g., SwiftData or CoreData integration).
- **`Security/`**: Keychain management, session handling, and authentication logic.
- **`Managers/`**: Domain-specific managers (e.g., `SyncManager`, `NotificationManager`).

---

## 4. Architecture & Design Patterns

### MVVM (Strict)
We follow a strict MVVM pattern to separate UI logic from business logic.
- **View**: Declarative SwiftUI views. Views should be passive and observe ViewModels.
- **ViewModel**: Responsible for preparing data for the view and handling user interactions. ViewModels **must** be annotated with `@MainActor`.
- **State Management**: Use `@StateObject` for ViewModel ownership and `@ObservedObject` for dependency injection.

### Repository Pattern
All data access must be abstracted via repositories.
- **Protocols**: Always define a protocol for repositories (e.g., `SummaryRepositoryProtocol`).
- **Implementation**: Real implementations reside in `WaniKaniCore`.
- **Injection**: ViewModels should depend on protocols, not concrete implementations, to facilitate testing.

---

## 5. Swift 6 & Concurrency

The project enforces **Strict Concurrency Checking**.

- **Main Thread Safety**: All ViewModels and UI-related classes must be marked with `@MainActor`.
- **Actors**: Use `actor` types for thread-safe state management in the core layer.
- **Structured Concurrency**: Prefer `async/await` and `Task` over completion handlers or Combine where appropriate.
- **Sendable**: Ensure all data models transferred between actors conform to `Sendable`.

```swift
@MainActor
class DashboardViewModel: ObservableObject {
    private let repository: SummaryRepositoryProtocol
    @Published private(set) var state: LoadingState<Summary> = .idle

    init(repository: SummaryRepositoryProtocol) {
        self.repository = repository
    }

    func loadData() async {
        state = .loading
        do {
            let summary = try await repository.fetchSummary()
            state = .success(summary)
        } catch {
            state = .failure(error)
        }
    }
}
```

---

## 6. Coding Standards & Style

### General Style
- **Naming**: `PascalCase` for types, `camelCase` for variables and functions.
- **Clarity**: Favor descriptive names over brevity (e.g., `fetchCurrentAssignments()` instead of `getAss()`).
- **Formatting**: Follow standard Swift guidelines. Use 4-space indentation.

### Error Handling
- **Domain Errors**: Use the `WaniKaniError` enum for app-specific errors.
- **No Force Unwraps**: Avoid `!` unless absolutely necessary (e.g., in tests or for constants that are guaranteed to exist).
- **Graceful Failure**: Always provide feedback to the user when an operation fails.

### Documentation
- Use DocC comments (`///`) for public APIs in `WaniKaniCore`.
- Explain the "why" for complex logic, not just the "what".

### Logging
- **SmartLogger**: Use `SmartLogger.shared` for all logging.
- **Debug Only**: Logs are wrapped in `#if DEBUG` and will be stripped from release builds.
- **Privacy**: Avoid logging sensitive user data (tokens, emails) in plain text.
- **Levels**: Use appropriate levels (`debug`, `info`, `error`, `fault`).

---

## 7. Testing Strategy

TDD (Test-Driven Development) is strongly encouraged.

- **Unit Tests**: Every ViewModel and Repository must have corresponding unit tests.
- **Mocks**: Use mock implementations of protocols for isolation.
- **Naming Convention**: `test_[functionName]_[scenario]_[expectedOutcome]`.
- **Coverage**: Aim for high coverage of business logic and edge cases.

```swift
func test_fetchSummary_networkError_returnsFailure() async {
    let mockRepo = MockSummaryRepository(shouldFail: true)
    let sut = DashboardViewModel(repository: mockRepo)
    
    await sut.loadData()
    
    if case .failure = sut.state {
        // Pass
    } else {
        XCTFail("Expected failure state")
    }
}
```

---

## 8. Git Workflow & Collaboration

### Branching Strategy
- **`main`**: The stable branch. Only merges from PRs are allowed.
- **Feature Branches**: `feature/short-description`.
- **Bug Fixes**: `fix/short-description`.

### Commit Guidelines
- **Atomic Commits**: Each commit should represent a single logical change.
- **Style**: Match the repository's existing commit style (Semantic or Plain, as detected).
- **Attribution**: Always include author attribution in automated commits.

### Pull Requests
- All changes must go through a PR.
- PRs must pass CI (build and tests) before merging.
- Include a clear summary of changes and any relevant screenshots for UI work.

---

## 9. Configuration & App Identity

The project's identity and build settings are managed in `project.yml`.

### Renaming the App
To change the app name or bundle identifier:
1. Open `project.yml`.
2. Locate the `PRODUCT_BUNDLE_IDENTIFIER` under the `WaniKani` target settings.
3. Update the value (e.g., `com.yourname.wanikani`).
4. Run `make generate` to apply the changes to the Xcode project.

---

## 10. API v2 Reference

- **Base URL**: `https://api.wanikani.com/v2`
- **Revision Header**: `Wanikani-Revision: 20170710`
- **Authentication**: Bearer token in `Authorization` header.
- **Rate Limits**: 60 requests per minute. Handle `429 Too Many Requests` gracefully.
- **Documentation**: Refer to the official [WaniKani API Docs](https://www.wanikani.com/api/v2) for endpoint specifics.

---

## 11. Guidelines for AI Agents

When working as an agent on this repository:
1. **Plan First**: Always create a todo list before executing complex tasks.
2. **Respect the Structure**: Place new files in the appropriate `Features` or `Core` directories.
3. **Verify**: Run `make build` and `make test` after any structural or logic changes.
4. **Regenerate**: If you add or remove files, you **must** run `make generate`.
5. **No Prototypes**: The prototypes (WebView, Hybrid) have been deprecated. Do not attempt to re-implement or reference them.

---

## 12. Agent Reporting Standards

When reporting task completion, you **MUST** include a "Technical Problem & Solution" section.

### Required Format
**Technical Analysis:**
- **Problem**: [Technical cause] (e.g., "Race condition in `fetchUser()` due to background thread access")
- **Solution**: [Code change] (e.g., "Added `@MainActor` to `PersistenceManager`")

**Example:**
> **Problem**: The app crashed on launch because `WaniKani/Shared` was missing from `project.yml` sources, creating an invalid bundle.
> **Solution**: Added `WaniKani/Shared` to the `sources` list in `project.yml` and regenerated the project.

---
*End of Documentation*

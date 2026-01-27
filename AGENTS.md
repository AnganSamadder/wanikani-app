# WaniKani iOS - Agentic Coding Guide

This documentation is the **primary source of truth** for AI agents and developers working on the WaniKani iOS project. It defines the architecture, build system, and strict coding conventions.

## 1. Quick Start & Commands

### Build System
The project is managed by `xcodegen`. **NEVER** modify `.xcodeproj` directly. Modify `project.yml` instead.

| Action | Command |
|--------|---------|
| **Regenerate Project** | `xcodegen generate` (Run after adding/removing files) |
| **Build (Native)** | `xcodebuild -scheme WaniKani-Native -destination 'platform=iOS Simulator,name=iPhone 16' build` |
| **Test (All)** | `xcodebuild -scheme WaniKani-Native -destination 'platform=iOS Simulator,name=iPhone 16' test` |
| **Test (Single)** | `xcodebuild -scheme WaniKani-Native -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:WaniKaniTests/DashboardViewModelTests/test_fetchSummary_success` |

### Key Files
- `project.yml`: Target & Scheme definitions.
- `AGENTS.md`: This file.
- `WaniKani/App/AppState.swift`: Prototype switching logic.

## 2. Architecture & Patterns

The app supports three modes via separate targets:
1.  **WaniKani-WebView**: Wrapper for existing web interface.
2.  **WaniKani-Native**: 100% SwiftUI + API v2 (The winner for production).
3.  **WaniKani-Hybrid**: Native shell + Web content.

### MVVM Pattern (Strict)
- **Model**: Immutable structs (API data).
- **View**: SwiftUI, declarative. **MUST** inject ViewModels.
- **ViewModel**: `@StateObject` (if owner) or `@ObservedObject`. **MUST** be `@MainActor`.

### Repository Pattern
- All data access is abstracted via repositories (`WaniKaniRepository`).
- **NEVER** call API directly from ViewModels.
- **ALWAYS** define a protocol for repositories to enable mocking.

## 3. Swift 6 & Concurrency
We enforce strict concurrency checking.

- **UI Components**: implicitly `@MainActor`.
- **ViewModels**: **MUST** be annotated with `@MainActor`.
- **Managers/Singletons**: Use `@MainActor static let shared` if they touch UI or strictly main-thread state.
- **Async/Await**: Prefer over completion handlers.

```swift
@MainActor
class DashboardViewModel: ObservableObject {
    // ...
}
```

## 4. Coding Standards

### Style & Formatting
- **Imports**: Alphabetical order. `import SwiftUI` first.
- **Types**: `PascalCase`.
- **Variables/Functions**: `camelCase`.
- **Properties**: Prefer `let` over `var` where possible.
- **Closures**: Use trailing closure syntax for last arguments.

### Error Handling
- **NO** `try!`. Use `do-catch` or `try?`.
- **NO** silent failures. Log or show user-facing errors.
- Use `WaniKaniError` enum for domain errors.

### Testing
- **TDD**: Write tests for ViewModels and Repositories.
- **Mocks**: Create `MockService` or `MockRepository` conforming to protocols.
- **Naming**: `test_methodName_condition_expectedResult`.

```swift
// Example Test
func test_fetchSummary_success() async {
    let mockRepo = MockRepository()
    let vm = DashboardViewModel(repository: mockRepo)
    await vm.fetchSummary()
    XCTAssertNotNil(vm.summary)
}
```

## 5. Environment & Targets (project.yml)

We use three separate application targets to allow side-by-side installation:
- `WaniKaniWebView` (`com.angansamadder.wanikani.webview`)
- `WaniKaniNative` (`com.angansamadder.wanikani.native`)
- `WaniKaniHybrid` (`com.angansamadder.wanikani.hybrid`)

**Note**: When adding a new file, ensure it is added to the correct target source list in `project.yml` if it's specific to a prototype, or `WaniKaniCore` if shared.

## 6. API v2 Reference
- **Base**: `https://api.wanikani.com/v2`
- **Header**: `Wanikani-Revision: 20170710`
- **Auth**: Bearer Token.
- **Rate Limit**: 60 req/min (Handle `429`).

## 7. Workflow for Agents
1.  **Plan**: Analyze requirements.
2.  **Modify**: Edit Swift files or `project.yml`.
3.  **Regenerate**: If files added/removed, run `xcodegen generate`.
4.  **Verify**: Run `xcodebuild build` to ensure no compilation errors.
5.  **Test**: Run relevant unit tests.

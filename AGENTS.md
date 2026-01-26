# WaniKani iOS Project Documentation

This document serves as a comprehensive guide to the architecture, patterns, and conventions used in the WaniKani iOS project. It is intended for developers and AI agents working on the codebase to ensure consistency and maintainability across all three prototype implementations.

## 1. Project Architecture

The WaniKani project is designed with a unique architecture that allows for simultaneous development and testing of three different mobile application paradigms: **WebView-based**, **Fully Native**, and **Hybrid**.

### Target and Schemes

The project consists of a single primary application target, `WaniKani`. To support the three prototype modes, we use Xcode Schemes that set environment variables to tell the application which mode to boot into.

- **WaniKani-WebView**: Boots the app in WebView mode. It primarily serves as a wrapper for the WaniKani web interface, augmented with native enhancements and userscript support.
- **WaniKani-Native**: Boots the app in Native mode. This mode uses SwiftUI for all UI components and communicates directly with the WaniKani API v2.
- **WaniKani-Hybrid**: Boots the app in Hybrid mode. This mode combines native navigation and critical features with WebView-based content for complex interactive elements like lessons and reviews.

### Prototype Mode Switching

The switching logic is handled at the very top of the application hierarchy. The `PROTOTYPE_MODE` environment variable is read by the `AppState` class, which then informs the `WaniKaniApp` which root view to instantiate.

#### AppState.swift Implementation

```swift
import SwiftUI

class AppState: ObservableObject {
    enum PrototypeMode: String {
        case webview, native, hybrid
    }
    
    var prototypeMode: PrototypeMode {
        // Reads from ProcessInfo to determine the mode set by the active Xcode Scheme
        let mode = ProcessInfo.processInfo.environment["PROTOTYPE_MODE"] ?? "webview"
        return PrototypeMode(rawValue: mode) ?? .webview
    }
}
```

#### WaniKaniApp.swift Root Switching

```swift
@main
struct WaniKaniApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            switch appState.prototypeMode {
            case .webview:
                WebViewRootView()
            case .native:
                NativeRootView()
            case .hybrid:
                HybridRootView()
            }
        }
    }
}
```

## 2. Prototype Comparison Table

The following table outlines the key differences and technical implementations of each prototype mode.

| Aspect | WebView | Native | Hybrid |
|--------|---------|--------|--------|
| **UI Rendering** | `WKWebView` (HTML/CSS) | Pure SwiftUI Components | Mixed (SwiftUI + `WKWebView`) |
| **Data Source** | WaniKani Website Content | WaniKani API v2 + SwiftData | API for Native, Web for Views |
| **Userscripts** | Full `WKUserScript` Support | Not Applicable | Partial Support in WebViews |
| **Offline Support**| Limited (Browser Caching) | Full Offline Sync & Storage | Partial (Cached Native Data) |
| **Navigation** | Web-based Navigation | Native `NavigationStack` | Native Shell + Web Content |
| **Performance** | Higher Overhead | Maximum Fluidity | Balanced |

## 3. WaniKani API v2

The WaniKani API v2 is a RESTful interface that provides access to user data, study material, and progress statistics.

### Base Configuration

- **Base URL**: `https://api.wanikani.com/v2`
- **Authentication**: Uses Bearer Token authentication. The API Key must be provided in the `Authorization` header.
- **Required Header**: `Wanikani-Revision: 20170710`. This header is mandatory for all requests to ensure compatibility with a specific version of the API schema.

### Rate Limiting

The API implements rate limiting to ensure fair usage.
- **Limit**: 60 requests per minute.
- **Handling**: If the limit is exceeded, the API returns a `429 Too Many Requests` status code along with a `Retry-After` header indicating the number of seconds to wait before retrying.

### Response Envelope Structure

All API responses follow a consistent envelope structure, containing metadata about the request and the actual resource data.

```json
{
  "object": "collection",
  "url": "https://api.wanikani.com/v2/subjects",
  "pages": {
    "per_page": 500,
    "next_url": "https://api.wanikani.com/v2/subjects?after_id=500",
    "previous_url": null
  },
  "total_count": 9400,
  "data_updated_at": "2023-10-27T15:45:00.000000Z",
  "data": [
    {
      "id": 1,
      "object": "radical",
      "url": "https://api.wanikani.com/v2/subjects/1",
      "data_updated_at": "2023-05-12T10:00:00.000000Z",
      "data": {
        "created_at": "2012-02-27T19:08:16.000000Z",
        "level": 1,
        "slug": "ground",
        "characters": "一",
        "meanings": [
          {
            "meaning": "Ground",
            "primary": true,
            "accepted_answer": true
          }
        ]
      }
    }
  ]
}
```

### Pagination

WaniKani API v2 uses cursor-based pagination. When fetching collections, if there are more results than the `per_page` limit, the `pages.next_url` field will contain the URI for the next set of results. Clients should follow these URLs until `next_url` is `null`.

## 4. MVVM Pattern (Model-View-ViewModel)

We strictly adhere to the MVVM pattern for all SwiftUI views to maintain a clean separation of concerns between UI logic and business logic.

### Principles
1. **Model**: Represents the data structures (mostly generated from API responses).
2. **View**: Declarative SwiftUI code that renders based on the state of the ViewModel.
3. **ViewModel**: An `ObservableObject` that holds the state, performs data fetching, and handles user interactions.

### Code Example: Dashboard

#### ViewModel
```swift
class DashboardViewModel: ObservableObject {
    @Published var summary: Summary?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let repository: WaniKaniRepository
    
    init(repository: WaniKaniRepository) {
        self.repository = repository
    }
    
    @MainActor
    func fetchSummary() async {
        isLoading = true
        do {
            self.summary = try await repository.getSummary()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
```

#### View
```swift
struct DashboardView: View {
    @StateObject var viewModel: DashboardViewModel
    
    var body: some View {
        List {
            if let summary = viewModel.summary {
                Section("Reviews") {
                    Text("Available Now: \(summary.reviews.count)")
                }
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .task {
            await viewModel.fetchSummary()
        }
    }
}
```

## 5. Repository Pattern

The Repository Pattern acts as a mediator between the ViewModel and the data sources (API, Local Database, Cache). It abstracts the details of where data comes from.

### Principles
- **Abstraction**: ViewModels don't know if data is coming from the network or a local SwiftData store.
- **Testability**: Makes it easy to swap real repositories with mock versions for unit testing.
- **Centralization**: Logic for merging local and remote data stays in one place.

### Code Example: Subject Repository

```swift
protocol SubjectRepository {
    func getSubject(id: Int) async throws -> Subject
    func getAllSubjects() async throws -> [Subject]
}

class WaniKaniSubjectRepository: SubjectRepository {
    private let apiService: APIService
    private let persistence: PersistenceProvider
    
    init(apiService: APIService, persistence: PersistenceProvider) {
        self.apiService = apiService
        self.persistence = persistence
    }
    
    func getSubject(id: Int) async throws -> Subject {
        // Check cache first
        if let cached = try? persistence.fetchSubject(id: id) {
            return cached
        }
        
        // Fetch from API and save to cache
        let subject = try await apiService.fetchSubject(id: id)
        try? persistence.saveSubject(subject)
        return subject
    }
    
    func getAllSubjects() async throws -> [Subject] {
        return try await apiService.fetchAllSubjects()
    }
}
```

## 6. Testing Conventions

We follow Test-Driven Development (TDD) principles wherever possible to ensure high code quality and prevent regressions.

### Unit Testing
- **Location**: All unit tests reside in the `WaniKaniTests` target.
- **Naming**: Test files should match the class being tested with a `Tests` suffix (e.g., `DashboardViewModelTests.swift`).
- **Structure**: Use the Given-When-Then pattern for test cases.

```swift
func test_dashboardViewModel_fetchSummary_success() async {
    // Given
    let mockRepo = MockWaniKaniRepository()
    let viewModel = DashboardViewModel(repository: mockRepo)
    let expectedSummary = Summary.mock()
    mockRepo.stubbedSummary = expectedSummary
    
    // When
    await viewModel.fetchSummary()
    
    // Then
    XCTAssertEqual(viewModel.summary, expectedSummary)
    XCTAssertFalse(viewModel.isLoading)
}
```

### Mocking
Dependency injection is used throughout the app. We create protocols for all services and repositories, allowing us to inject `Mock` implementations during testing.

## 7. Code Style

### SwiftUI Conventions
- Prefer `struct` over `class` for views.
- Use `@StateObject` for ViewModels owned by the view, and `@ObservedObject` for those passed in.
- Keep view bodies small. Extract subviews into separate computed properties or smaller components.

### Naming
- Follow standard Swift naming conventions (CamelCase for types, camelCase for variables/functions).
- Boolean variables should be prefixed with `is`, `has`, or `should` (e.g., `isLoading`, `hasContent`).

### Error Handling
- Use custom `Error` enums to represent domain-specific errors.
- Prefer `async/await` with `do-catch` blocks over completion handlers.
- Always provide user-friendly error messages when propagating errors to the UI.

```swift
enum WaniKaniError: Error {
    case unauthorized
    case rateLimited(retryAfter: Int)
    case networkError(Error)
    case decodingError
}
```

## 8. Conclusion

By following these patterns and utilizing the multi-prototype architecture, we can rapidly iterate on the WaniKani user experience while maintaining a robust and scalable native foundation. This `AGENTS.md` file should be updated whenever significant architectural changes occur to keep the entire development team aligned.

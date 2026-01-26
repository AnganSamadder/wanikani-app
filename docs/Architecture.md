# WaniKani iOS Architecture Documentation

This document provides a deep-dive into the technical architecture of the WaniKani iOS application. It covers the high-level system design, the unique multi-prototype approach, data management strategies, and module responsibilities.

## 1. High-Level Architecture

The WaniKani iOS project is structured as a modular workspace designed for flexibility, testability, and clear separation of concerns. The codebase is divided into two primary targets: the main application target (`WaniKani`) and a core business logic framework (`WaniKaniCore`).

### Module Structure

- **WaniKani (App Target)**: This target contains the UI layer, navigation logic, and prototype-specific implementations. It is built entirely using SwiftUI and follows the MVVM pattern.
- **WaniKaniCore (Framework)**: A dedicated framework that houses the shared business logic, networking stack, data models, and persistence layer. By isolating these components, we ensure that they can be tested independently of the UI and potentially reused across different platforms or targets.

### Dependency Graph

The dependency flow is strictly unidirectional:
`WaniKani (App)` -> `WaniKaniCore (Framework)` -> `External Dependencies (SwiftData, etc.)`

The application target depends on `WaniKaniCore` for all data-related operations. ViewModels in the `WaniKani` target interact with Repositories defined in `WaniKaniCore`, which in turn manage the complexity of networking and local storage.

## 2. Prototype Architecture Details

One of the most unique aspects of this project is its ability to boot into three distinct architectural modes: WebView, Native, and Hybrid. This is controlled via environment variables and Xcode Schemes.

### WebView Prototype
The WebView mode serves as a sophisticated wrapper around the WaniKani web interface.
- **WKWebView Configuration**: We use a custom `WKWebView` setup with optimized process pools and configuration profiles.
- **Message Handlers**: Native-to-JS and JS-to-Native communication is handled via `WKScriptMessageHandler`. This allows the app to intercept specific web events and trigger native functionality (e.g., haptic feedback during reviews).
- **Userscript Injection**: Support for community-made userscripts is implemented by injecting `WKUserScript` instances at document start or end. This maintains feature parity with the desktop experience while adding mobile optimizations.

### Native Prototype
The Native mode is a fully immersive iOS experience built from the ground up.
- **SwiftUI Views**: All UI components are native SwiftUI views, providing maximum performance and a consistent system feel.
- **SwiftData Persistence**: Local storage is managed using `SwiftData`, allowing for robust offline support and efficient data querying.
- **API Client**: A custom networking stack in `WaniKaniCore` handles authentication, rate limiting, and response decoding for the WaniKani API v2.

### Hybrid Prototype
The Hybrid mode combines the best of both worlds.
- **Native Shell**: High-frequency navigation and critical dashboard features are implemented natively for speed.
- **WebView Content**: Complex, highly interactive elements like the Lesson and Review sessions are rendered via `WKWebView` to leverage the existing web-based logic while being hosted within a native container.

## 3. Data Flow and Synchronization

The application follows a predictable data flow pattern to ensure state consistency.

### Standard Flow: API to View
1. **API**: Data is fetched from the WaniKani API v2.
2. **Models**: JSON responses are decoded into Swift models within `WaniKaniCore`.
3. **Repositories**: The Repository layer abstracts the data source. It decides whether to return cached data or fetch fresh data from the network.
4. **ViewModels**: ViewModels transform the raw models into view-friendly state.
5. **Views**: SwiftUI views reactively update based on the ViewModel's `@Published` properties.

### Offline Sync Strategy
The application employs an "Offline-First" approach for the Native and Hybrid prototypes.
- **Write-Ahead Logging**: Changes made offline are queued and synchronized when a connection is restored.
- **Delta Updates**: We use the `data_updated_at` timestamps from the API to fetch only the changes since the last sync, minimizing data usage and battery consumption.
- **Background Refresh**: The app utilizes Background Tasks to periodically sync data even when not in the foreground.

## 4. Module Responsibilities

### WaniKani/App
- **Entry Point**: `WaniKaniApp.swift` manages the application lifecycle.
- **App State**: `AppState` handles the prototype mode switching and global authentication state.

### WaniKani/Features
- **Feature Views**: SwiftUI views for Dashboard, Reviews, Lessons, etc.
- **ViewModels**: Logic specific to individual screens.

### WaniKaniCore/Networking
- **APIService**: Core networking logic using `URLSession`.
- **Authentication**: Managing Bearer tokens and the `Wanikani-Revision` header.

### WaniKaniCore/Models
- **Domain Models**: Swift structures representing Subjects, Assignments, Reviews, etc.
- **Codable Support**: Logic for mapping API responses to internal models.

### WaniKaniCore/Persistence
- **SwiftData Container**: Management of the persistent store.
- **Migrations**: Handling schema updates as the app evolves.

This architecture ensures that WaniKani iOS remains robust, scalable, and adaptable to future changes in the WaniKani platform.

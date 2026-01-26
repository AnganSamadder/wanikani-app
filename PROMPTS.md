# WaniKani Development Prompt Templates

This document contains a collection of reusable prompt templates designed for developers and AI agents working on the WaniKani iOS project. These templates ensure consistency across the three prototype modes (WebView, Native, and Hybrid) and adhere to the project's architectural standards.

---

## 1. Add New Feature with TDD
**Goal**: Implement a new feature using the Red-Green-Refactor cycle to ensure high code quality and prevent regressions.

### Context/Requirements
- **Feature Name**: [Describe the feature, e.g., "Mnemonic Search"]
- **Target Mode**: [WebView / Native / Hybrid]
- **Architecture**: Must follow the MVVM and Repository patterns as defined in `AGENTS.md`.
- **Testing**: Tests must be placed in the `WaniKaniTests` target using the Given-When-Then pattern.

### Step-by-Step Instructions
1.  **Red Phase**: Create a new test file `[FeatureName]Tests.swift`. Write a failing test case that defines the expected behavior of the new feature. Ensure the test fails to compile or fails upon execution.
2.  **Green Phase**: Implement the minimum amount of code in the ViewModel and/or Repository to make the test pass. Do not worry about code elegance at this stage.
3.  **Refactor Phase**: Clean up the implementation. Extract subviews, improve variable naming, and ensure adherence to Swift coding conventions without breaking the tests.
4.  **Repeat**: Move to the next requirement of the feature and repeat the cycle.

### Files to Create/Modify
- `Sources/ViewModels/[FeatureName]ViewModel.swift`
- `Sources/Views/[FeatureName]View.swift`
- `Tests/WaniKaniTests/[FeatureName]Tests.swift`
- `Sources/Repositories/[Relevant]Repository.swift`

### Verification Steps
- Run `Cmd+U` in Xcode to execute all tests.
- Ensure the specific feature tests pass with 100% success.
- Verify `lsp_diagnostics` are clean for the new files.

---

## 2. Implement WaniKani API Endpoint
**Goal**: Add support for a new resource from the WaniKani API v2.

### Context/Requirements
- **Endpoint**: [e.g., `GET /assignments`]
- **Authentication**: Must use Bearer Token and include `Wanikani-Revision: 20170710`.
- **Data Structure**: Map the JSON response to a Swift `Codable` struct, maintaining the envelope structure.

### Step-by-Step Instructions
1.  **Model Creation**: Define the `Codable` structs for the resource and its data attributes in `Sources/Models/`.
2.  **API Service Update**: Add a new method to `APIService.swift` to fetch the data from the specified endpoint. Use `async/await`.
3.  **Repository Integration**: Update the relevant Repository (or create a new one) to handle the fetching and caching of this new data.
4.  **Error Handling**: Implement custom error handling for `429 Rate Limited` and `401 Unauthorized` responses.

### Files to Create/Modify
- `Sources/Models/[ResourceName].swift`
- `Sources/Networking/APIService.swift`
- `Sources/Repositories/[ResourceName]Repository.swift`

### Verification Steps
- Use a mock API response in unit tests to verify decoding logic.
- Verify that the `Wanikani-Revision` header is correctly set in the network request.
- Ensure pagination logic is handled if the endpoint returns a collection.

---

## 3. Add Userscript Support
**Goal**: Implement or enhance userscript functionality in the WebView or Hybrid modes.

### Context/Requirements
- **Script Purpose**: [Describe what the script does, e.g., "Double Check"]
- **Prototype Mode**: Primarily affects `WebViewRootView` or the `WKWebView` components in Hybrid mode.
- **Injection Point**: Determine if the script should run at `document_start` or `document_end`.

### Step-by-Step Instructions
1.  **Script Preparation**: Save the JavaScript content into a `.js` file in the `Resources/Scripts/` directory.
2.  **Injection Logic**: Use `WKUserScript` to inject the script into the `WKUserContentController`.
3.  **Native Communication**: If the script needs to send data back to the app, set up a `WKScriptMessageHandler` and define a message name.
4.  **UI Feedback**: Provide a toggle in the app settings to enable/disable the userscript.

### Files to Create/Modify
- `Resources/Scripts/[ScriptName].js`
- `Sources/WebView/UserScriptManager.swift`
- `Sources/Views/SettingsView.swift`

### Verification Steps
- Load the WebView and verify the script's effect on the page content.
- Check the Xcode console for any JavaScript errors passed through `WKScriptMessageHandler`.
- Toggle the script off in Settings and verify it is no longer injected upon reload.

---

## 4. Debug Offline Sync Issue
**Goal**: Troubleshoot and resolve discrepancies between local SwiftData and remote API state.

### Context/Requirements
- **Issue Description**: [e.g., "Level progress not updating when offline"]
- **Scope**: Affects the Repository layer and Persistence layer.
- **Constraint**: Must ensure data integrity and handle conflict resolution (Remote wins by default).

### Step-by-Step Instructions
1.  **Logging**: Add detailed print statements or use `OSLog` in the Repository to track when sync starts, fails, or succeeds.
2.  **Network Simulation**: Use the Network Link Conditioner to simulate "Offline" or "High Latency" environments.
3.  **State Inspection**: Use the SwiftData debugger or export the SQLite database to verify the local state.
4.  **Fix Implementation**: Ensure the `save` operations in the Repository correctly update existing records rather than creating duplicates.

### Files to Create/Modify
- `Sources/Repositories/[Affected]Repository.swift`
- `Sources/Persistence/PersistenceProvider.swift`

### Verification Steps
- Perform an action offline, then reconnect and verify the data is pushed to the API.
- Verify that the `data_updated_at` timestamp is used to determine if local data is stale.
- Run the app and check for any SwiftData-related crashes during heavy sync operations.

---

## 5. Create New SwiftUI View
**Goal**: Scaffold a new UI component or screen following the project's MVVM pattern.

### Context/Requirements
- **View Name**: [e.g., "SubjectDetailView"]
- **Input Data**: [e.g., A `Subject` object]
- **Design**: Should match the WaniKani brand guidelines (colors, typography).

### Step-by-Step Instructions
1.  **ViewModel Setup**: Create a `[ViewName]ViewModel.swift` class conforming to `ObservableObject`. Add `@Published` properties for the view state.
2.  **View Implementation**: Create a `[ViewName].swift` struct. Use `@StateObject` to instantiate the ViewModel.
3.  **Subviews**: Break down complex UI into smaller, private computed properties or separate `struct` components.
4.  **Preview**: Add a `PreviewProvider` with mock data to facilitate rapid UI iteration.

### Files to Create/Modify
- `Sources/Views/[ViewName].swift`
- `Sources/ViewModels/[ViewName]ViewModel.swift`
- `Sources/Components/[SmallComponent].swift`

### Verification Steps
- Verify the view renders correctly in the Xcode Preview canvas.
- Ensure all UI strings are localized (if applicable).
- Check that the view handles "Loading" and "Error" states gracefully.

---

## Conclusion

By using these templates, you ensure that the WaniKani iOS app remains robust, testable, and maintainable across all its prototype implementations. Always refer back to `AGENTS.md` for the latest architectural standards.

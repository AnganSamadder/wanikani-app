# Testing Strategy for WaniKani iOS

Testing is a core pillar of the WaniKani iOS development lifecycle. To maintain high code quality, prevent regressions across our multi-prototype architecture (WebView, Native, Hybrid), and ensure a seamless user experience, we adhere to a rigorous testing strategy. This document outlines our standards, patterns, and expectations for all contributors.

## 1. Test-Driven Development (TDD) Approach

We strongly encourage a **Test-Driven Development (TDD)** workflow. TDD ensures that every piece of logic is justified by a requirement and that our code remains modular and testable from the start.

The process follows the classic **RED-GREEN-REFACTOR** cycle:
- **RED**: Write a failing test for a small piece of functionality. The test must fail because the code does not yet exist.
- **GREEN**: Write the minimum amount of code necessary to make the test pass. Do not over-engineer at this stage.
- **REFACTOR**: Clean up the implementation while keeping the tests green. Improve readability, remove duplication, and optimize performance.

## 2. Test Naming Conventions

Clarity in test results is paramount. When a test fails, the name should tell you exactly what broke and under what conditions. We use a structured naming convention:

`test{MethodName}_{scenario}_{expectedResult}`

**Examples:**
- `testFetchSummary_whenNetworkFails_returnsNetworkError`
- `testCalculateLevelProgress_withValidData_returnsCorrectPercentage`
- `testToggleReview_whenPressed_updatesViewState`

## 3. Test Structure: Given-When-Then

All tests must follow the **Given-When-Then** pattern to ensure they are easy to read and maintain.

```swift
func testGetSubject_whenCached_returnsCachedValue() async {
    // Given
    let expectedSubject = Subject.mock(id: 1, slug: "ground")
    mockPersistence.stubbedSubject = expectedSubject
    
    // When
    let result = try? await repository.getSubject(id: 1)
    
    // Then
    XCTAssertEqual(result, expectedSubject)
    XCTAssertTrue(mockApiService.fetchSubjectCalledCount == 0)
}
```

- **Given**: Setup the environment, state, and mocks.
- **When**: Execute the specific action being tested.
- **Then**: Assert the expected outcome or state change.

## 4. Unit Testing

Unit tests form the base of our testing pyramid. They are fast, isolated, and focused on specific units of logic.

### ViewModels
We test ViewModels to ensure state transitions occur correctly in response to user actions or data updates.
- Verify `@Published` properties update as expected.
- Ensure error states are handled gracefully.
- Validate that the ViewModel interacts correctly with its dependencies (Repositories).

### Repositories
Repositories are tested to ensure data integrity and proper handling of local vs. remote data.
- Verify that the repository attempts to fetch from the cache before hitting the network.
- Ensure that data fetched from the API is correctly persisted.
- Test edge cases like rate limiting and malformed JSON responses.

## 5. Mocking and Dependency Injection

We use **Protocol-based Dependency Injection** to facilitate isolation. Every service or repository must have a corresponding protocol.

### MockRepository Pattern
Instead of using complex mocking frameworks, we prefer hand-written mocks that implement the protocol and allow us to control return values (stubbing) and track calls (spying).

```swift
class MockSubjectRepository: SubjectRepository {
    var stubbedSubject: Subject?
    var fetchSubjectCalledCount = 0
    
    func getSubject(id: Int) async throws -> Subject {
        fetchSubjectCalledCount += 1
        if let stubbedSubject = stubbedSubject {
            return stubbedSubject
        }
        throw WaniKaniError.notFound
    }
}
```

## 6. UI Testing

We use **XCUITest** for high-level integration testing and critical user flows. UI tests should be kept to a minimum as they are slower and more fragile than unit tests.
- **Critical Flows**: Login, completing a review session, and navigating between main dashboard tabs.
- **Verification**: Use accessibility identifiers to interact with UI elements.

## 7. Code Coverage Target

We maintain a high standard for test coverage, particularly for core business logic.
- **WaniKaniCore Target**: 80% or higher.
- **ViewModels/Repositories**: Aim for 90%+ coverage.
- UI components and boilerplate code are excluded from these strict targets, though testing them is still encouraged.

## 8. Running Tests

Tests can be run directly within Xcode (`Cmd + U`) or via the command line for CI/CD pipelines.

### xcodebuild Commands
To run tests for the WaniKani target from the terminal:

```bash
xcodebuild test \
  -project WaniKani.xcodeproj \
  -scheme WaniKani-Native \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

By following these standards, we ensure that the WaniKani app remains robust and maintainable as we scale the project and iterate on our prototype implementations.

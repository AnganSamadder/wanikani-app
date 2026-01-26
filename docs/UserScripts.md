# WaniKani UserScript Support in the iOS Application

## Introduction to UserScripts
WaniKani has a vibrant and dedicated community of developers who create "UserScripts" to enhance and customize the learning experience. These scripts are essentially JavaScript snippets that run on top of the WaniKani website, modifying its behavior, adding new features, or altering its appearance. Traditionally, these scripts are managed via browser extensions like GreaseMonkey, TamperMonkey, or ViolentMonkey on desktop browsers. In the context of the WaniKani iOS application, we recognize the immense value these community contributions bring to the platform. Consequently, we provide varying levels of support for these scripts across our three prototype modes—WebView, Native, and Hybrid—to ensure that users can continue to benefit from the rich ecosystem of community-driven improvements even on a mobile device.

## Finding and Discovering Scripts: The GreasyFork API
The primary repository for WaniKani UserScripts is GreasyFork. To facilitate the seamless discovery and installation of these scripts within our application, we utilize the GreasyFork API. This allows the app to programmatically fetch the latest versions of scripts and display them to the user. Specifically, we can query for scripts targeting the WaniKani domain using the following endpoint:

`https://greasyfork.org/en/scripts.json?site=wanikani.com`

This API returns a structured JSON collection containing metadata for each script, including its name, version, author, description, and direct download links for the JavaScript source. In the application's settings or "Script Manager," this data is used to present a curated or searchable list of scripts that users can easily toggle on or off. By leveraging this API, we ensure that users always have access to the most up-to-date community enhancements without manual downloads.

## WebView Prototype: Full First-Class Integration
In the **WebView Prototype**, UserScript support is a foundational feature. Since this version of the app is essentially a highly optimized wrapper around the WaniKani web interface, we can leverage native iOS web technologies to inject community scripts directly into the browsing context.

- **WKUserScript Injection**: We utilize the `WKUserContentController` class to manage script injection. Each enabled UserScript is added as a `WKUserScript` object, which can be configured to run at `document_start` (before the page renders) or `document_end` (after the DOM is fully loaded). This granular control allows scripts to perform tasks ranging from early-stage URL redirection to post-load UI manipulation.
- **CSS and Style Injection**: Many scripts rely on custom CSS to theme the WaniKani interface. We support this by injecting `<style>` elements dynamically via JavaScript or by using private `WKWebView` configuration APIs where applicable. This ensures that layout modifications and "dark mode" scripts are applied seamlessly and consistently.
- **Environment Shimming**: Many scripts expect a full browser extension environment with specific GreaseMonkey APIs (like `GM_getValue`, `GM_setValue`, or `GM_xmlhttpRequest`). To maintain compatibility, we provide a JavaScript "shim" that translates these calls into native iOS operations or local storage interactions.

## Native Prototype: Data Extraction and Logic Porting
In the **Native Prototype**, the primary interface is built entirely with SwiftUI, meaning there is no persistent WebView for the main dashboard or menus. However, some UserScripts provide invaluable logic that is difficult or time-consuming to replicate purely in Swift.

- **Hidden or Headless WebViews**: To support certain data-heavy scripts, we occasionally spin up an invisible "headless" `WKWebView`. This background environment runs specific scripts—such as those that calculate complex progress statistics or process subject data—and passes the results back to the native Swift code via `window.webkit.messageHandlers`.
- **Core Logic Porting**: For the most popular and essential scripts, our long-term goal is to port their core functionality directly into the native Swift codebase. This provides a significantly faster, more stable, and more energy-efficient experience than running an interpreted script in the background.

## Hybrid Prototype: The Balanced Bridge
The **Hybrid Prototype** takes a middle ground, using native Swift for navigation and core dashboard features while rendering complex, highly interactive sessions (like Lessons and Reviews) in a WebView.

- **Contextual Script Injection**: UserScripts are primarily active within these specialized WebView segments. For example, a "Double Check" script would be injected specifically into the Review WebView to allow users to re-type answers if they made a typo, preventing unnecessary frustration.
- **Communication Bridge**: We implement a robust message bridge that allows scripts running inside a WebView to communicate with the native shell. This enables scripts to trigger native features, such as haptic feedback on a correct answer or updating a native iOS progress bar based on the script's calculations.

## Popular Scripts and Their Community Impact
The WaniKani community has produced several "must-have" scripts that our application strives to support as comprehensively as possible:

- **Ultimate Timeline**: Offers a detailed and customizable visualization of upcoming review sessions, helping users plan their study time more effectively.
- **Double Check**: Perhaps the most popular script, it allows users to mark an answer as correct if they made a simple typo or to re-answer a question, which is crucial for maintaining morale during long review sessions.
- **Self-Study Quiz**: Enables users to create custom quiz sessions based on specific levels, item types, or SRS stages, providing more flexibility than the standard WaniKani flow.
- **Anki Mode**: Transforms the review interface to behave more like Anki, where the answer is revealed first and the user manually decides if they "passed" or "failed" the item.

## Implementation Details: The WKUserContentController
The technical heart of our UserScript implementation is the `WKUserContentController`. This component of `WebKit` allows us to define the relationship between the native Swift code and the JavaScript environment.

- **Injection Timing Strategy**: We generally prefer injecting scripts at `atDocumentEnd` for UI modifications to ensure the base page is stable. However, scripts that override core WaniKani functions must be injected at `atDocumentStart` to ensure they hook into the system before the original site code executes.
- **Message Handlers for Persistence**: We register specific message handlers that allow scripts to request data from the app (such as the user's API key) or to persist their own settings in the app's local storage. This bridges the gap between the ephemeral nature of a webpage and the permanent storage of a native application.

By providing this robust framework for UserScript support, the WaniKani iOS app ensures that it remains a powerful and customizable tool for Japanese language learners, honoring the rich history of community innovation that has made WaniKani what it is today.

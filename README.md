# WaniKani iOS App - Three Prototypes

## Setup

1. Install XcodeGen:
   ```bash
   brew install xcodegen
   ```

2. Generate Xcode project:
   ```bash
   xcodegen generate
   ```

3. Open the project:
   ```bash
   open WaniKani.xcodeproj
   ```

## Schemes

- **WaniKani-WebView**: WebView-based prototype with userscript injection
- **WaniKani-Native**: Fully native SwiftUI implementation
- **WaniKani-Hybrid**: Mixed native + WebView approach

Select the scheme from Xcode's scheme selector to test each prototype.

## Project Structure

- `WaniKani/` - iOS app source code
- `WaniKaniCore/` - Shared framework (networking, models, persistence)
- `WaniKaniTests/` - Unit tests
- `WaniKaniUITests/` - UI tests
- `docs/` - Documentation
- `Scripts/` - Build and automation scripts

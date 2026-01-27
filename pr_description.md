# PR Description: Migration to Professional Production Structure

## Summary
This PR transitions the repository from a multi-prototype experiment to a unified, production-ready iOS application based on the winning "Native" prototype. It establishes a clean architecture, standardizes naming, and implements professional engineering practices.

## Key Changes

### 1. Architecture & Structure
- **Unified Target**: Replaced `WaniKaniNative`, `WaniKaniWebView`, and `WaniKaniHybrid` with a single `WaniKani` app target.
- **Refactored Directory**:
  - Moved all feature code to `WaniKani/Features/`.
  - Moved app lifecycle code to `WaniKani/App/`.
  - Deleted `WaniKani/Prototypes/` and all experimental code.
- **Clean MVVM**: Enforced strict separation of Views and ViewModels in feature directories.

### 2. Standardization
- **Renaming**: Removed "Native" prefix from all files (e.g., `NativeDashboardView` -> `DashboardView`).
- **Bundle ID**: Set to `com.angansamadder.wanikani`.
- **Source of Truth**: Rewrote `AGENTS.md` to reflect the new strict standards (Swift 6, Concurrency, Git Workflow).

### 3. CI/CD & Quality
- **GitHub Actions**: Added `.github/workflows/ci.yml` to automatically build and test on every PR.
- **Strict Concurrency**: Enabled strict concurrency checking in build settings.
- **Zero Warnings**: Verified build is clean.

## Verification
- **Build**: `make build` ✅
- **Test**: `make test` ✅
- **Generate**: `make generate` ✅

## Next Steps
- Merge this PR to `main`.
- Begin feature iteration on the stable foundation.

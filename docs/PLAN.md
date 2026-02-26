# WaniKani Professional Turborepo Migration + Full Native Rewrite Plan

## Brief Summary
This plan converts the repo into a professional Bun + Turborepo monorepo, scaffolds an Android native shell (Kotlin + Compose), and rewrites the iOS app from the current UI to design-driven SwiftUI with a single production visual system.

The app ships one feature set and data behavior, including full site parity goals and native community read/auth actions.

## Locked Decisions
- Package manager: `bun`
- Monorepo layout: `apps/ + packages/`
- Android shell: Native Kotlin + Compose
- iOS rewrite strategy: Full rewrite (UI + ViewModels + core logic)
- Visual delivery: Single production visual system
- Feature scope: Full site parity target
- Community: Native read + auth actions
- Design source strategy: Export canonical `.pen` milestone snapshots into repo

## Target Repository Structure
```text
/
  apps/
    ios/
      project.yml
      Makefile
      WaniKani/
      WaniKaniCore/
      WaniKaniTests/
      WaniKaniUITests/
      designs/
        wanikani-master.pen
        frame-manifest.json
        reference/
    android/
      app/
      gradle/
      gradlew
      settings.gradle.kts
      build.gradle.kts
  packages/
    design-tokens/
    parity-matrix/
    tooling/
      scripts/
      configs/
  turbo.json
  package.json
  bun.lockb
  bunfig.toml
```

## Turborepo Setup Plan (Maximized Features)
1. Initialize Bun workspace root.
- Add root `package.json` with `workspaces: ["apps/*", "packages/*"]`.
- Set `packageManager` to Bun version pin.

2. Add `turbo.json` with full task graph.
- Tasks: `lint`, `typecheck`, `test`, `build`, `dev`, `clean`, `design:sync`, `ios:generate`, `ios:build`, `ios:test`, `android:build`, `android:test`.
- Use `dependsOn` for deterministic DAG (`build` depends on `^build`, `test` depends on `build` where needed).
- Configure `outputs` for cacheable tasks.
- Configure `inputs` to avoid false cache invalidation.
- Add environment passthrough keys for iOS build destinations and API env.
- Enable run summaries and task graph visibility for CI diagnostics.

3. Add monorepo scripts for filtered workflows.
- Root scripts: `bun run turbo run build --filter=apps/ios`, `--filter=apps/android`, `--filter=packages/*`.
- Add “affected” style commands based on Turbo filters for faster dev loops.

4. CI and remote cache integration.
- Add Turbo remote cache support (provider-neutral config path).
- Ensure iOS/Android jobs run with cache-aware `turbo run` invocations.

## iOS Rewrite Plan (Single Build Variant)
1. Move existing iOS code under `apps/ios` with path-preserving migration.
- Keep XcodeGen as source of truth.
- Update `apps/ios/project.yml` source paths.
- Regenerate `.xcodeproj` from `apps/ios`.

2. Standardize on one app scheme.
- Keep `WaniKani` as the primary app scheme.
- Keep `WaniKani-Unit` as the unit-test scheme.

3. Replace app shell with the new architecture.
- New root: `apps/ios/WaniKani/AppFlow`.
- Typed routing and feature coordinators.
- Dependency container and feature registration.

4. Rewrite shared UI kit into one cohesive visual system.
- `SharedApp/Theme/*`
- Behavioral parity and visual consistency are both required.

5. Replace existing screens feature-by-feature.
- Authentication/onboarding.
- Dashboard.
- Reviews flow.
- Lessons flow.
- Subject lists/details.
- Statistics/progress.
- Settings sections.
- Search.
- Extra study modes.
- Community surfaces.

6. Legacy UI deletion gate.
- Remove old feature views/components only after parity tests pass.
- Remove obsolete prototype references and stale auth screens.

## Android Shell Plan (Now Empty, Future-Ready)
1. Scaffold native Android app in `apps/android`.
- Kotlin DSL Gradle.
- Compose UI.
- Min/target SDK aligned with modern baseline.

2. Build minimal shell screens.
- Launch screen.
- Placeholder navigation host with tabs/routes matching iOS parity matrix naming.
- Settings placeholder with theme mode control stub.

3. Add Turbo tasks.
- `android:build`
- `android:test`
- `android:lint`
- All cacheable with defined outputs.

4. Future expansion contract.
- Keep app modular to mirror iOS feature namespaces.
- Reserve integration points for shared specs/tokens from `packages/`.

## Design-to-Code Pipeline
1. Canonical design export milestones.
- Source live Pencil editor state.
- Export into `apps/ios/designs/wanikani-master.pen` at each gate.
- Generate `frame-manifest.json` mapping frame IDs to Swift routes/components.
- Store light/dark references in `apps/ios/designs/reference/`.

2. Token extraction and typed usage.
- Add `packages/design-tokens` as canonical token store.
- Generate iOS assets/theme constants from tokens.
- Generate Android Compose theme placeholders from same token package.
- Keep theme styling separate from base semantic token names.

3. SwiftGen integration.
- Add `swiftgen.yml` under `apps/ios`.
- Generate typed color/image/string accessors.
- Wire generation to Turbo task `ios:generate`.

## Full Site Parity Execution Strategy
1. Maintain explicit parity matrix in `packages/parity-matrix`.
- Columns: route, data source, status, tests, known gaps.
- Every route must be marked with one clear completion status.

2. Community native read/auth actions implementation.
- Add Discourse API client layer in iOS core.
- Implement auth/session handling.
- Implement topic read/list/search/detail and actions (reply, like, bookmark, post create/edit).
- Add explicit rate-limit and permission failure states.

3. No WebView fallback policy.
- Any unimplemented route blocks parity completion.

## Important API/Interface Changes
- New app-level interfaces:
- `AppRoute`
- `FeatureRoute`
- `AppContainerProtocol`
- New repository protocols replacing current narrow set:
- `DashboardRepositoryProtocol`
- `ReviewSessionRepositoryProtocol`
- `LessonSessionRepositoryProtocol`
- `SubjectCatalogRepositoryProtocol`
- `SubjectDetailRepositoryProtocol`
- `SettingsRepositoryProtocol`
- `SearchRepositoryProtocol`
- `ExtraStudyRepositoryProtocol`
- `CommunityRepositoryProtocol`
- New community interfaces:
- `DiscourseAPIClientProtocol`
- `CommunityAuthSessionStore`
- `CommunityActionServiceProtocol`
- New tooling interfaces:
- Token generation contract in `packages/design-tokens`
- Parity matrix schema in `packages/parity-matrix`

## Step-by-Step Delivery Phases

1. Phase A: Monorepo Foundation
- Create Bun workspace root.
- Add Turbo DAG and root scripts.
- Move iOS project to `apps/ios`.
- Keep builds green after path migration.
- Gate: `turbo run ios:generate ios:build ios:test` passes.

2. Phase B: Android Shell Bootstrap
- Scaffold native Android Compose shell.
- Add Turbo Android tasks.
- Gate: `turbo run android:build android:test` passes.

3. Phase C: Design and Token System
- Export canonical `.pen`.
- Build frame manifest.
- Build token package and generators.
- Wire SwiftGen and token generation tasks.
- Gate: deterministic generation from one command.

4. Phase D: iOS Architecture
- Build new root, routing, DI, feature boundaries.
- Gate: app boots with placeholder shell.

5. Phase E: Feature Rewrite
- Implement each feature route in the production visual system.
- Implement full native community actions.
- Maintain parity matrix per route completion.
- Gate: all matrix rows complete.

6. Phase F: Legacy Removal + Hardening
- Remove old UI/features after parity and tests pass.
- Clean docs and scripts.
- Final CI cache tuning and build speed profiling.
- Gate: clean repo structure, passing pipelines, no orphaned legacy screens.

## Test Cases and Acceptance Scenarios
1. Monorepo/tooling tests
- Turbo graph correctness.
- Cache hit verification on repeated runs.
- Filtered run correctness per app/package.

2. iOS unit tests
- ViewModel state transitions by feature.
- Repository error/retry/rate-limit behavior.
- Theme resolution logic.
- Community auth/session lifecycle and action failures.

3. iOS UI tests
- Login to dashboard.
- Lesson flow end-to-end.
- Review flow end-to-end.
- Search and subject detail navigation.
- Extra study routes.
- Settings sections.
- Community topic read + reply + like/bookmark actions.

4. Snapshot tests
- Every mapped route.
- Light and dark mode across the app.
- Baseline device and dynamic type checkpoints.

5. Android shell tests
- App starts and renders navigation host.
- Placeholder route smoke tests.
- Build/lint/test via Turbo.

## Assumptions and Defaults
- The canonical design state comes from live Pencil export, not the current placeholder `WaniKani.pen`.
- Existing docs referencing old prototype modes will be updated/retired.
- Full rewrite means old UI and old ViewModel/core implementations are replaced after parity gates.
- App has one cohesive visual system with full dark mode support.
- Android remains an empty but production-structured shell in this phase.
- Bun is the single package manager for workspace and Turbo orchestration.

## Definition of Done
- Repo is a Bun + Turborepo monorepo with `apps/ios`, `apps/android`, and `packages/*`.
- iOS app builds and runs through `WaniKani` and `WaniKani-Unit`.
- Full parity matrix marked complete.
- Native community read/auth actions work.
- Dark mode validated for every implemented route.
- Legacy UI removed and architecture/doc/tooling are coherent and professional.

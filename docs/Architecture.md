# WaniKani Monorepo Architecture

## Top-Level

- `apps/ios`: SwiftUI app + `WaniKaniCore` framework + tests
- `apps/android`: Kotlin/Compose native shell
- `packages/design-tokens`: canonical semantic token source and code generation
- `packages/parity-matrix`: route parity matrix + validation
- `packages/tooling`: workspace scripts and CI config templates

## iOS Architecture

- Source of truth: `apps/ios/project.yml` (XcodeGen)
- App composition root: `apps/ios/WaniKani/AppFlow`
- Shared business logic in `apps/ios/WaniKaniCore`
- Strict MVVM boundaries with repository protocols

## Android Architecture

- Native Kotlin DSL Gradle project at `apps/android`
- Jetpack Compose shell with parity-aligned route naming
- Placeholder settings includes dark-mode control stub for future theme system

## Design-to-Code Pipeline

- Canonical `.pen` snapshot in `apps/ios/designs/wanikani-master.pen`
- `frame-manifest.json` maps design frames to Swift routes/components
- `packages/design-tokens` generates platform artifacts:
  - Swift token constants into iOS app source
  - Kotlin token constants into Android app source

## Build Orchestration

- Bun workspaces at root
- Turborepo task DAG in `turbo.json`
- Cache-aware app/package tasks with filtered and affected runs

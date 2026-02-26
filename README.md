# WaniKani Monorepo

Native WaniKani clients and shared tooling, organized as a Bun + Turborepo workspace.

## Workspace Layout

- `apps/ios`: Native SwiftUI app (XcodeGen source of truth)
- `apps/android`: Native Kotlin + Compose shell
- `packages/design-tokens`: Canonical semantic design tokens + generators
- `packages/parity-matrix`: Route parity source + validation
- `packages/tooling`: Monorepo automation scripts/config templates

## Quick Start

```bash
bun install
bun run ios:generate
bun run ios:open
bun run ios:build
bun run android:build
```

For Android local development, ensure SDK is installed and either:
- set `ANDROID_HOME` / `ANDROID_SDK_ROOT`, or
- create `/Users/angansamadder/Code/WaniKani/apps/android/local.properties` with `sdk.dir=/path/to/sdk`.

## Common Commands

```bash
# full workspace
bun run build
bun run test
bun run lint

# affected-only runs
bun run build:affected
bun run test:affected

# iOS
bun run ios:build
bun run ios:test
bun run ios:test:unit:scheme

# turbo graph + summaries
bun run graph:build
bun run build:summary
```

## iOS Notes

- Do not edit `.xcodeproj` directly.
- Source of truth is `apps/ios/project.yml`.
- Regenerate with `bun run ios:generate`.
- Root generation is supported: `bun run ios:generate` also emits `/Users/angansamadder/Code/WaniKani/WaniKani.xcodeproj`.
- Open from root with `bun run ios:open` (or `make open`).

## Remote Cache

Use environment variables in CI for Turbo remote cache:

- `TURBO_TEAM`
- `TURBO_TOKEN`
- optional `TURBO_API` (self-hosted endpoint)

See `packages/tooling/configs/turbo-remote-cache.example.env`.

## CI

GitHub Actions runs a monorepo pipeline with:
- `packages` job: shared packages lint/typecheck/test/build
- `android` job: Android shell build/test/lint
- `ios` job: generate/build/test for `WaniKani` (unit tests)

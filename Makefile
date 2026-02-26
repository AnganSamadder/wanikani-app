# WaniKani monorepo Makefile convenience wrapper.

.PHONY: help install generate open build test lint typecheck clean \
	ios-generate ios-open ios-build ios-test ios-test-unit \
	android-build android-test android-lint packages-build

help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  install          Install workspace dependencies with Bun"
	@echo "  generate         Generate iOS project + token artifacts"
	@echo "  open             Open root WaniKani.xcodeproj in Xcode"
	@echo "  build            Build all workspace packages/apps via Turbo"
	@echo "  test             Test all workspace packages/apps via Turbo"
	@echo "  lint             Lint all workspace packages/apps via Turbo"
	@echo "  typecheck        Typecheck all workspace packages/apps via Turbo"
	@echo "  clean            Clean all workspace packages/apps via Turbo"
	@echo "  ios-generate     Generate iOS project artifacts"
	@echo "  ios-open         Open root WaniKani.xcodeproj in Xcode"
	@echo "  ios-build        Build iOS app"
	@echo "  ios-test         Run iOS full test suite for active scheme"
	@echo "  ios-test-unit    Run iOS unit tests only for active scheme"
	@echo "  android-build    Build Android shell"
	@echo "  android-test     Run Android unit tests"
	@echo "  android-lint     Run Android lint"
	@echo "  packages-build   Build shared packages"

install:
	bun install

generate:
	bun run design:sync
	bun run ios:generate

open:
	@if [ ! -d WaniKani.xcodeproj ]; then $(MAKE) generate; fi
	bun run ios:open

build:
	bun run build

test:
	bun run test

lint:
	bun run lint

typecheck:
	bun run typecheck

clean:
	bun run clean

ios-generate:
	bun run ios:generate

ios-open:
	@if [ ! -d WaniKani.xcodeproj ]; then $(MAKE) generate; fi
	bun run ios:open

ios-build:
	bun run ios:build

ios-test:
	bun run ios:test

ios-test-unit:
	bun run ios:test:unit

android-build:
	bun run android:build

android-test:
	bun run android:test

android-lint:
	bun run android:lint

packages-build:
	bun run packages:build

# WaniKani iOS Makefile

# Variables
DEVICE_NAME ?= iPhone 16
PLATFORM ?= iOS Simulator
# Explicitly set OS to 18.3.1 to match available simulator for iPhone 16
DESTINATION = platform=$(PLATFORM),name=$(DEVICE_NAME),OS=18.3.1

.PHONY: all help generate build-all build-native build-webview build-hybrid test clean

all: generate build-all ## Generate project and build all targets (Default)

help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

generate: ## Regenerate the Xcode project using xcodegen
	xcodegen generate

open: ## Open the generated project in Xcode
	xed .

build-all: build-native build-webview build-hybrid ## Build all targets

build-native: ## Build the Native prototype
	xcodebuild -scheme WaniKani-Native -destination '$(DESTINATION)' build

build-webview: ## Build the WebView prototype
	xcodebuild -scheme WaniKani-WebView -destination '$(DESTINATION)' build

build-hybrid: ## Build the Hybrid prototype
	xcodebuild -scheme WaniKani-Hybrid -destination '$(DESTINATION)' build

test: ## Run unit tests
	xcodebuild -scheme WaniKani-Native -destination '$(DESTINATION)' test

clean: ## Clean build folder
	xcodebuild clean
	rm -rf *.xcodeproj

# WaniKani iOS Makefile

# Variables
DEVICE_NAME ?= iPhone 16
PLATFORM ?= iOS Simulator
# Explicitly set OS to 18.3.1 to match available simulator for iPhone 16
DESTINATION = platform=$(PLATFORM),name=$(DEVICE_NAME),OS=18.3.1

.PHONY: all help generate build test clean open

all: generate build ## Generate project and build (Default)

help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

generate: ## Regenerate the Xcode project using xcodegen
	xcodegen generate

open: ## Open the generated project in Xcode
	xed .

build: ## Build the app
	xcodebuild -scheme WaniKani -destination '$(DESTINATION)' build

test: ## Run unit tests
	xcodebuild -scheme WaniKani -destination '$(DESTINATION)' test

clean: ## Clean build folder
	xcodebuild clean
	rm -rf *.xcodeproj

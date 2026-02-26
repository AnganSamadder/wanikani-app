# WaniKani iOS Makefile

# Variables
DEVICE_NAME ?= iPhone 17
PLATFORM ?= iOS Simulator
IOS_SCHEME ?= WaniKani
DESTINATION = platform=$(PLATFORM),name=$(DEVICE_NAME)

.PHONY: all help generate build test clean open

all: generate build ## Generate project and build (Default)

help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

generate: ## Regenerate the Xcode project using xcodegen
	xcodegen generate
	swiftgen config run --config swiftgen.yml

open: ## Open the generated project in Xcode
	xed .

build: ## Build the app
	xcodebuild -project WaniKani.xcodeproj -scheme $(IOS_SCHEME) -destination '$(DESTINATION)' build

test: ## Run unit tests
	xcodebuild -project WaniKani.xcodeproj -scheme $(IOS_SCHEME) -destination '$(DESTINATION)' test

clean: ## Clean build folder
	xcodebuild -project WaniKani.xcodeproj clean -scheme $(IOS_SCHEME)
	rm -rf *.xcodeproj

#!/bin/bash
set -euo pipefail

echo "WaniKani iOS setup"

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Install from https://brew.sh"
  exit 1
fi

if ! command -v xcodegen >/dev/null 2>&1; then
  brew install xcodegen
fi

if ! command -v swiftgen >/dev/null 2>&1; then
  brew install swiftgen
fi

if ! command -v swiftlint >/dev/null 2>&1; then
  brew install swiftlint
fi

./Scripts/generate.sh

echo "Setup complete."

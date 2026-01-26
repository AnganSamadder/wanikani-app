#!/bin/bash
set -e

echo "🛠️  WaniKani iOS Project Setup"
echo "=============================="

if ! command -v brew &>/dev/null; then
	echo "❌ Homebrew not found. Please install: https://brew.sh"
	exit 1
fi

if ! command -v xcodegen &>/dev/null; then
	echo "📦 Installing XcodeGen..."
	brew install xcodegen
else
	echo "✅ XcodeGen already installed"
fi

if ! command -v swiftlint &>/dev/null; then
	echo "📦 Installing SwiftLint..."
	brew install swiftlint
else
	echo "✅ SwiftLint already installed"
fi

echo "🔧 Generating Xcode project..."
xcodegen generate

echo ""
echo "✅ Setup complete! Open WaniKani.xcodeproj to get started."

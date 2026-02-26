#!/bin/bash
set -e

echo "🔍 Running SwiftLint..."

if ! command -v swiftlint &>/dev/null; then
	echo "⚠️  SwiftLint not found. Install with: brew install swiftlint"
	exit 1
fi

swiftlint lint --quiet
echo "✅ Lint complete!"

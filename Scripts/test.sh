#!/bin/bash
set -e

echo "🧪 Running WaniKani Tests..."
echo "============================"

xcodebuild test \
	-project WaniKani.xcodeproj \
	-scheme WaniKani-Native \
	-destination 'platform=iOS Simulator,name=iPhone 16' \
	-quiet \
	2>&1 | xcbeautify || xcodebuild test \
	-project WaniKani.xcodeproj \
	-scheme WaniKani-Native \
	-destination 'platform=iOS Simulator,name=iPhone 16' \
	-quiet

echo "✅ Tests complete!"

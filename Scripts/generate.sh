#!/bin/bash
set -e

echo "🔧 Regenerating Xcode project..."
xcodegen generate
echo "✅ Done! Project regenerated."

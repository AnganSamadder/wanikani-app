#!/bin/bash
set -euo pipefail

echo "Regenerating Xcode project and SwiftGen artifacts..."
xcodegen generate --spec project.yml
swiftgen config run --config swiftgen.yml
echo "Done."

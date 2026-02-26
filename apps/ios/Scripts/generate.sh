#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROOT_DIR="$(cd "${IOS_DIR}/../.." && pwd)"

echo "Regenerating Xcode projects and SwiftGen artifacts..."

# Local iOS project (apps/ios/WaniKani.xcodeproj)
xcodegen generate --spec "${IOS_DIR}/project.yml" --project "${IOS_DIR}"

# Root project (WaniKani.xcodeproj) used by root Makefile/workspace scripts
xcodegen -s "${IOS_DIR}/project.yml" -p "${ROOT_DIR}" -r "${IOS_DIR}"

swiftgen config run --config "${IOS_DIR}/swiftgen.yml"
echo "Done."

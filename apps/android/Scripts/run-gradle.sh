#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ANDROID_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ $# -lt 1 ]]; then
  echo "Usage: ./Scripts/run-gradle.sh <gradle-task> [additional args...]" >&2
  exit 1
fi

SDK_ROOT="$("${SCRIPT_DIR}/bootstrap-android-sdk.sh" --print-sdk-root)"
export ANDROID_HOME="${SDK_ROOT}"
export ANDROID_SDK_ROOT="${SDK_ROOT}"

cd "${APP_ANDROID_DIR}"
./gradlew "$@"

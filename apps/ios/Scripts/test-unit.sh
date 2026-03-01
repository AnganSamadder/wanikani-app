#!/bin/bash
set -euo pipefail

SCHEME="${IOS_SCHEME:-WaniKani-Unit}"
DESTINATION="${IOS_DESTINATION:-$(./Scripts/select-simulator.sh)}"
TEST_TIMEOUT_SECONDS="${IOS_TEST_TIMEOUT_SECONDS:-1200}"
RESULT_BUNDLE="build/UnitTestResults.xcresult"
OUTPUT_LOG="build/unit-test-output.txt"
BUILD_LOG="build/unit-build-for-testing-output.txt"

mkdir -p build
rm -rf "${RESULT_BUNDLE}" "${OUTPUT_LOG}" "${BUILD_LOG}"

# Ensure watchdog processes are always cleaned up, even when tests fail.
cleanup() {
  if [[ -n "${watchdog_pid:-}" ]]; then
    kill "${watchdog_pid}" >/dev/null 2>&1 || true
  fi
  if [[ -n "${watchdog_sleep_pid:-}" ]]; then
    kill "${watchdog_sleep_pid}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT INT TERM

if [[ "${DESTINATION}" == *"id="* ]]; then
  UDID="${DESTINATION##*=}"
  xcrun simctl boot "${UDID}" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "${UDID}" -b >/dev/null 2>&1 || true
fi

echo "Running unit tests for scheme: ${SCHEME}"
echo "Step 1/2: build-for-testing"
xcodebuild build-for-testing \
  -project WaniKani.xcodeproj \
  -scheme "${SCHEME}" \
  -destination "${DESTINATION}" \
  -destination-timeout 120 \
  -derivedDataPath build/DerivedData \
  -maximum-parallel-testing-workers 1 \
  -parallel-testing-enabled NO \
  "$@" \
  | tee "${BUILD_LOG}"

XCTESTRUN_PATH="$(find build/DerivedData/Build/Products -maxdepth 1 -name "${SCHEME}_iphonesimulator*.xctestrun" | head -n 1)"
if [[ -z "${XCTESTRUN_PATH}" ]]; then
  XCTESTRUN_PATH="$(find build/DerivedData/Build/Products -maxdepth 1 -name "*.xctestrun" | head -n 1)"
fi

if [[ -z "${XCTESTRUN_PATH}" ]]; then
  echo "Unable to locate .xctestrun file under build/DerivedData/Build/Products." >&2
  exit 1
fi

echo "Step 2/2: test-without-building using ${XCTESTRUN_PATH}"
(
  xcodebuild test-without-building \
    -xctestrun "${XCTESTRUN_PATH}" \
    -destination "${DESTINATION}" \
    -resultBundlePath "${RESULT_BUNDLE}" \
    -parallel-testing-enabled NO \
    -test-timeouts-enabled YES \
    -default-test-execution-time-allowance 60 \
    -maximum-test-execution-time-allowance 180 \
    -only-testing:WaniKaniTests \
    "$@" \
    | tee "${OUTPUT_LOG}"
) &
test_pid=$!

# Watchdog: timeout the test process without leaving orphaned sleep jobs.
sleep "${TEST_TIMEOUT_SECONDS}" &
watchdog_sleep_pid=$!

(
  wait "${watchdog_sleep_pid}" >/dev/null 2>&1 || exit 0
  if kill -0 "${test_pid}" >/dev/null 2>&1; then
    echo "Timed out after ${TEST_TIMEOUT_SECONDS}s. Stopping xcodebuild..."
    pkill -f "xcodebuild test-without-building -xctestrun" >/dev/null 2>&1 || true
    pkill -f "xcodebuild test -project WaniKani.xcodeproj -scheme ${SCHEME}" >/dev/null 2>&1 || true
    kill -TERM "${test_pid}" >/dev/null 2>&1 || true
  fi
) &
watchdog_pid=$!

set +e
wait "${test_pid}"
test_status=$?
kill "${watchdog_sleep_pid}" >/dev/null 2>&1 || true
kill "${watchdog_pid}" >/dev/null 2>&1 || true
set -e

if [[ "${test_status}" -ne 0 ]]; then
  exit "${test_status}"
fi

echo "Unit tests complete. Results: ${RESULT_BUNDLE}"

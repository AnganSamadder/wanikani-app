#!/bin/bash
set -euo pipefail

SCHEME="${IOS_SCHEME:-WaniKani}"
DESTINATION="${IOS_DESTINATION:-$(./Scripts/select-simulator.sh)}"
TEST_TIMEOUT_SECONDS="${IOS_TEST_TIMEOUT_SECONDS:-1800}"
RESULT_BUNDLE="build/TestResults.xcresult"
OUTPUT_LOG="build/test-output.txt"

mkdir -p build
rm -rf "${RESULT_BUNDLE}" "${OUTPUT_LOG}"

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

# Boot selected simulator when destination uses explicit UDID.
if [[ "${DESTINATION}" == *"id="* ]]; then
  UDID="${DESTINATION##*=}"
  xcrun simctl boot "${UDID}" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "${UDID}" -b >/dev/null 2>&1 || true
fi

echo "Running tests for scheme: ${SCHEME}"
(
  xcodebuild test \
    -project WaniKani.xcodeproj \
    -scheme "${SCHEME}" \
    -destination "${DESTINATION}" \
    -destination-timeout 120 \
    -derivedDataPath build/DerivedData \
    -resultBundlePath "${RESULT_BUNDLE}" \
    -parallel-testing-enabled NO \
    -test-timeouts-enabled YES \
    -default-test-execution-time-allowance 90 \
    -maximum-test-execution-time-allowance 240 \
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

echo "Tests complete. Results: ${RESULT_BUNDLE}"

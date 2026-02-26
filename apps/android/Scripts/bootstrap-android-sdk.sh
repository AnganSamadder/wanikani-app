#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ANDROID_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

find_sdk_root() {
  if [[ -n "${ANDROID_SDK_ROOT:-}" && -d "${ANDROID_SDK_ROOT}" ]]; then
    echo "${ANDROID_SDK_ROOT}"
    return 0
  fi

  if [[ -n "${ANDROID_HOME:-}" && -d "${ANDROID_HOME}" ]]; then
    echo "${ANDROID_HOME}"
    return 0
  fi

  if [[ -f "${APP_ANDROID_DIR}/local.properties" ]]; then
    local sdk_dir
    sdk_dir="$(grep '^sdk.dir=' "${APP_ANDROID_DIR}/local.properties" | sed 's/^sdk.dir=//' | sed 's#\\:#:#g' || true)"
    if [[ -n "${sdk_dir}" && -d "${sdk_dir}" ]]; then
      echo "${sdk_dir}"
      return 0
    fi
  fi

  if [[ -d "/opt/homebrew/share/android-commandlinetools" ]]; then
    echo "/opt/homebrew/share/android-commandlinetools"
    return 0
  fi

  if [[ -d "${HOME}/Library/Android/sdk" ]]; then
    echo "${HOME}/Library/Android/sdk"
    return 0
  fi

  return 1
}

ensure_sdkmanager() {
  if command -v sdkmanager >/dev/null 2>&1; then
    return 0
  fi

  local candidate="/opt/homebrew/share/android-commandlinetools/cmdline-tools/latest/bin"
  if [[ -x "${candidate}/sdkmanager" ]]; then
    export PATH="${candidate}:${PATH}"
    return 0
  fi

  if command -v brew >/dev/null 2>&1; then
    brew install --cask android-commandlinetools
    export PATH="/opt/homebrew/share/android-commandlinetools/cmdline-tools/latest/bin:${PATH}"
    return 0
  fi

  echo "Android command-line tools not found and Homebrew is unavailable." >&2
  return 1
}

write_local_properties() {
  local sdk_root="$1"
  local escaped="${sdk_root//:/\\:}"
  printf "sdk.dir=%s\n" "${escaped}" > "${APP_ANDROID_DIR}/local.properties"
}

ensure_packages() {
  local sdk_root="$1"
  local need_install=0

  [[ -d "${sdk_root}/platform-tools" ]] || need_install=1
  [[ -d "${sdk_root}/platforms/android-35" ]] || need_install=1
  [[ -d "${sdk_root}/build-tools/35.0.0" ]] || need_install=1

  if [[ "${need_install}" -eq 0 ]]; then
    return 0
  fi

  yes | sdkmanager --sdk_root="${sdk_root}" --licenses >/dev/null || true
  sdkmanager --sdk_root="${sdk_root}" \
    "platform-tools" \
    "platforms;android-35" \
    "build-tools;35.0.0"
}

main() {
  ensure_sdkmanager

  local sdk_root
  if ! sdk_root="$(find_sdk_root)"; then
    sdk_root="/opt/homebrew/share/android-commandlinetools"
  fi

  mkdir -p "${sdk_root}"
  export ANDROID_SDK_ROOT="${sdk_root}"
  export ANDROID_HOME="${sdk_root}"

  ensure_packages "${sdk_root}"
  write_local_properties "${sdk_root}"

  if [[ "${1:-}" == "--print-sdk-root" ]]; then
    echo "${sdk_root}"
    return 0
  fi

  echo "Android SDK ready at ${sdk_root}"
}

main "${@:-}"

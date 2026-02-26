#!/bin/bash
set -euo pipefail

# Returns a deterministic iOS simulator destination string.
# Priority order favors modern iPhone Pro devices.

python3 <<'PY'
import json
import subprocess
import sys

preferred_names = [
    "iPhone 17 Pro",
    "iPhone 17",
    "iPhone 16 Pro",
    "iPhone 16",
    "iPhone 15 Pro",
    "iPhone 15",
]

try:
    raw = subprocess.check_output(
        ["xcrun", "simctl", "list", "devices", "available", "-j"],
        text=True,
    )
except subprocess.CalledProcessError:
    sys.exit("Unable to list simulators.")

data = json.loads(raw)
candidates = []

for runtime, devices in data.get("devices", {}).items():
    if "iOS" not in runtime:
        continue
    for device in devices:
        if not device.get("isAvailable"):
            continue
        name = device.get("name", "")
        udid = device.get("udid", "")
        if not name.startswith("iPhone ") or not udid:
            continue
        candidates.append((name, udid))

if not candidates:
    sys.exit("No available iPhone simulator found.")

for wanted in preferred_names:
    for name, udid in candidates:
        if name == wanted:
            print(f"platform=iOS Simulator,id={udid}")
            raise SystemExit(0)

# Fallback deterministic alphabetical choice.
name, udid = sorted(candidates, key=lambda x: x[0])[0]
print(f"platform=iOS Simulator,id={udid}")
PY

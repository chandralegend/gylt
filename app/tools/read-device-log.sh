#!/bin/bash
# Prints the Screen Time spike log (written by the app AND its extensions) from the connected iPhone.
# Usage: tools/read-device-log.sh [device-id]
set -euo pipefail
DEVICE="${1:-15591424-83E1-5491-8921-6355EE5CB2E8}"
GROUP="group.org.leafmonkey.gylt"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
if xcrun devicectl device copy from --device "$DEVICE" --domain-type appGroupDataContainer \
     --domain-identifier "$GROUP" --source debug-log.txt --destination "$TMP/debug-log.txt" >/dev/null 2>&1; then
  cat "$TMP/debug-log.txt"
else
  echo "(no log yet: nothing has been written, or the phone is locked)"
fi

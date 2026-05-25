#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME=${APP_NAME:-MClipboard}
APP_BUNDLE="${ROOT_DIR}/${APP_NAME}.app"

# Kill existing
pkill -f "${APP_NAME}.app/Contents/MacOS/${APP_NAME}" 2>/dev/null || true
pkill -x "${APP_NAME}" 2>/dev/null || true
sleep 0.3

# Package
echo "==> Building..."
SIGNING_MODE=adhoc "${ROOT_DIR}/Scripts/package_app.sh" release

# Launch
echo "==> Launching..."
open "${APP_BUNDLE}" || {
  "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" >/dev/null 2>&1 &
  disown
}

# Verify
for _ in {1..10}; do
  if pgrep -f "${APP_NAME}.app/Contents/MacOS/${APP_NAME}" >/dev/null 2>&1; then
    echo "✅ ${APP_NAME} is running."
    exit 0
  fi
  sleep 0.3
done

echo "❌ App exited immediately."
exit 1

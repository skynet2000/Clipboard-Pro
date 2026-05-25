#!/usr/bin/env bash
set -euo pipefail

CONF=${1:-release}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

APP_NAME=${APP_NAME:-MClipboard}
BUNDLE_ID=${BUNDLE_ID:-com.mclipboard.app}
MACOS_MIN_VERSION=${MACOS_MIN_VERSION:-14.0}

if [[ -f "$ROOT/version.env" ]]; then
  source "$ROOT/version.env"
else
  MARKETING_VERSION=${MARKETING_VERSION:-1.0.0}
  BUILD_NUMBER=${BUILD_NUMBER:-1}
fi

HOST_ARCH=$(uname -m)

swift build -c "$CONF" --arch "$HOST_ARCH"

APP="$ROOT/${APP_NAME}.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

BUILD_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key><string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key><string>${BUNDLE_ID}</string>
    <key>CFBundleExecutable</key><string>${APP_NAME}</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>${MARKETING_VERSION}</string>
    <key>CFBundleVersion</key><string>${BUILD_NUMBER}</string>
    <key>LSMinimumSystemVersion</key><string>${MACOS_MIN_VERSION}</string>
    <key>LSUIElement</key><true/>
    <key>CFBundleIconFile</key><string>Icon</string>
    <key>BuildTimestamp</key><string>${BUILD_TIMESTAMP}</string>
    <key>GitCommit</key><string>${GIT_COMMIT}</string>
</dict>
</plist>
PLIST

BINARY_SRC=".build/${HOST_ARCH}-apple-macosx/$CONF/${APP_NAME}"
if [[ ! -f "$BINARY_SRC" ]]; then
  BINARY_SRC=".build/$CONF/${APP_NAME}"
fi

cp "$BINARY_SRC" "$APP/Contents/MacOS/$APP_NAME"
chmod +x "$APP/Contents/MacOS/$APP_NAME"

# Copy resources
RES_DIR="$ROOT/Sources/$APP_NAME/Resources"
if [[ -d "$RES_DIR" ]]; then
  cp -R "$RES_DIR/." "$APP/Contents/Resources/"
fi

# SPM resource bundles
BUILD_DIR="$(dirname "$BINARY_SRC")"
shopt -s nullglob
for bundle in "${BUILD_DIR}/"*.bundle; do
  cp -R "$bundle" "$APP/Contents/Resources/"
done
shopt -u nullglob

# Icon
ICON="$ROOT/Icon.icns"
if [[ -f "$ICON" ]]; then
  cp "$ICON" "$APP/Contents/Resources/Icon.icns"
fi

# Clean extended attributes
xattr -cr "$APP"
find "$APP" -name '._*' -delete

# Ad-hoc sign
codesign --force --sign - "$APP"

echo "✅ Created $APP"

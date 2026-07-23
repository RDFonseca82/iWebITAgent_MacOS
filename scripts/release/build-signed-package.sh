#!/bin/bash
set -euo pipefail

VERSION="${1:?Usage: build-signed-package.sh VERSION BUILD OUTPUT_DIR}"
BUILD="${2:?Usage: build-signed-package.sh VERSION BUILD OUTPUT_DIR}"
OUTPUT_DIR="${3:?Usage: build-signed-package.sh VERSION BUILD OUTPUT_DIR}"

: "${APPLE_TEAM_ID:?APPLE_TEAM_ID is required}"
: "${DEVELOPER_ID_APPLICATION_IDENTITY:?DEVELOPER_ID_APPLICATION_IDENTITY is required}"
: "${DEVELOPER_ID_INSTALLER_IDENTITY:?DEVELOPER_ID_INSTALLER_IDENTITY is required}"
: "${UPDATE_CHANNEL_CONFIG_PATH:?UPDATE_CHANNEL_CONFIG_PATH is required}"

if [[ ! -f "$UPDATE_CHANNEL_CONFIG_PATH" ]]; then
  echo "Update channel configuration not found: $UPDATE_CHANNEL_CONFIG_PATH" >&2
  exit 66
fi

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
DERIVED_DIR="$ROOT_DIR/.build/apple-release"
PRODUCTS_DIR="$DERIVED_DIR/Products"
PAYLOAD_DIR="$DERIVED_DIR/Payload"
SCRIPTS_DIR="$ROOT_DIR/scripts/release/package-scripts"
UNSIGNED_PKG="$DERIVED_DIR/iWebIT-unsigned.pkg"
SIGNED_PKG="$OUTPUT_DIR/iWebIT-${VERSION}-${BUILD}.pkg"
INSTALL_DIR="$PAYLOAD_DIR/Library/Application Support/iWebITAgent"

rm -rf "$DERIVED_DIR"
mkdir -p "$PRODUCTS_DIR" "$INSTALL_DIR" "$PAYLOAD_DIR/Library/LaunchDaemons" \
  "$PAYLOAD_DIR/Library/LaunchAgents" "$OUTPUT_DIR"

xcodegen generate --spec "$ROOT_DIR/project-v2.yml"

for scheme in iWebITService-v2 iWebIT-v2 iWebITSysTray-v2; do
  xcodebuild \
    -project "$ROOT_DIR/iWebITAgent-v2.xcodeproj" \
    -scheme "$scheme" \
    -configuration Release \
    -destination "generic/platform=macOS" \
    -derivedDataPath "$DERIVED_DIR/DerivedData" \
    CONFIGURATION_BUILD_DIR="$PRODUCTS_DIR" \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="$DEVELOPER_ID_APPLICATION_IDENTITY" \
    CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
    OTHER_CODE_SIGN_FLAGS="--timestamp" \
    MARKETING_VERSION="$VERSION" \
    CURRENT_PROJECT_VERSION="$BUILD" \
    build
done

cp -R "$PRODUCTS_DIR/iWebIT.app" "$INSTALL_DIR/"
cp -R "$PRODUCTS_DIR/iWebITAgent.app" "$INSTALL_DIR/"
cp "$PRODUCTS_DIR/iWebITService" "$INSTALL_DIR/"
cp "$UPDATE_CHANNEL_CONFIG_PATH" "$INSTALL_DIR/update-channel.json"
cp "$ROOT_DIR/iWebITInstaller/payload/app.iwebit.agent.xpc.plist" \
  "$PAYLOAD_DIR/Library/LaunchDaemons/app.iwebit.agent.service.plist"
cp "$ROOT_DIR/iWebITInstaller/payload/app.iwebit.agent.menubar.plist" \
  "$PAYLOAD_DIR/Library/LaunchAgents/app.iwebit.agent.menubar.plist"

validate_release_signature() {
  local signed_path="$1"
  local signature_details
  local entitlements

  signature_details="$(codesign --display --verbose=4 "$signed_path" 2>&1)"
  if ! grep -q '^Timestamp=' <<<"$signature_details"; then
    echo "Secure timestamp missing from signature: $signed_path" >&2
    exit 65
  fi

  entitlements="$(codesign --display --entitlements :- "$signed_path" 2>/dev/null || true)"
  if grep -q 'com.apple.security.get-task-allow' <<<"$entitlements"; then
    echo "Development entitlement get-task-allow found in release signature: $signed_path" >&2
    exit 65
  fi
}

codesign --verify --deep --strict --verbose=2 "$INSTALL_DIR/iWebIT.app"
codesign --verify --deep --strict --verbose=2 "$INSTALL_DIR/iWebITAgent.app"
codesign --verify --strict --verbose=2 "$INSTALL_DIR/iWebITService"
validate_release_signature "$INSTALL_DIR/iWebIT.app"
validate_release_signature "$INSTALL_DIR/iWebITAgent.app"
validate_release_signature "$INSTALL_DIR/iWebITService"

pkgbuild \
  --root "$PAYLOAD_DIR" \
  --scripts "$SCRIPTS_DIR" \
  --identifier app.iwebit.agent.pkg \
  --version "$VERSION" \
  --install-location / \
  "$UNSIGNED_PKG"

productsign \
  --sign "$DEVELOPER_ID_INSTALLER_IDENTITY" \
  "$UNSIGNED_PKG" \
  "$SIGNED_PKG"

pkgutil --check-signature "$SIGNED_PKG"
echo "$SIGNED_PKG"

#!/bin/bash
set -euo pipefail

PACKAGE_PATH="${1:?Usage: notarize-with-api-key.sh PACKAGE_PATH API_KEY_PATH}"
API_KEY_PATH="${2:?Usage: notarize-with-api-key.sh PACKAGE_PATH API_KEY_PATH}"

: "${NOTARY_KEY_ID:?NOTARY_KEY_ID is required}"
: "${NOTARY_ISSUER_ID:?NOTARY_ISSUER_ID is required}"

xcrun notarytool submit "$PACKAGE_PATH" \
  --key "$API_KEY_PATH" \
  --key-id "$NOTARY_KEY_ID" \
  --issuer "$NOTARY_ISSUER_ID" \
  --wait
xcrun stapler staple "$PACKAGE_PATH"
xcrun stapler validate "$PACKAGE_PATH"
spctl --assess --type install --verbose=4 "$PACKAGE_PATH"

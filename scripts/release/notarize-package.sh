#!/bin/bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /absolute/path/to/iWebIT.pkg" >&2
  exit 64
fi

PACKAGE_PATH="$1"

if [[ ! -f "$PACKAGE_PATH" ]]; then
  echo "Package not found: $PACKAGE_PATH" >&2
  exit 66
fi

if [[ -z "${IWEBIT_NOTARY_KEYCHAIN_PROFILE:-}" ]]; then
  echo "IWEBIT_NOTARY_KEYCHAIN_PROFILE is required." >&2
  exit 78
fi

pkgutil --check-signature "$PACKAGE_PATH"
spctl --assess --type install --verbose=4 "$PACKAGE_PATH"
xcrun notarytool submit "$PACKAGE_PATH" \
  --keychain-profile "$IWEBIT_NOTARY_KEYCHAIN_PROFILE" \
  --wait
xcrun stapler staple "$PACKAGE_PATH"
xcrun stapler validate "$PACKAGE_PATH"
spctl --assess --type install --verbose=4 "$PACKAGE_PATH"

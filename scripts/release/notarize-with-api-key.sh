#!/bin/bash
set -euo pipefail

PACKAGE_PATH="${1:?Usage: notarize-with-api-key.sh PACKAGE_PATH API_KEY_PATH [DIAGNOSTICS_DIR]}"
API_KEY_PATH="${2:?Usage: notarize-with-api-key.sh PACKAGE_PATH API_KEY_PATH [DIAGNOSTICS_DIR]}"
DIAGNOSTICS_DIR="${3:-$(dirname "$PACKAGE_PATH")}"

: "${NOTARY_KEY_ID:?NOTARY_KEY_ID is required}"
: "${NOTARY_ISSUER_ID:?NOTARY_ISSUER_ID is required}"

mkdir -p "$DIAGNOSTICS_DIR"
SUBMIT_RESULT_PATH="$DIAGNOSTICS_DIR/notary-submit.json"
NOTARY_LOG_PATH="$DIAGNOSTICS_DIR/notary-log.json"

set +e
xcrun notarytool submit "$PACKAGE_PATH" \
  --key "$API_KEY_PATH" \
  --key-id "$NOTARY_KEY_ID" \
  --issuer "$NOTARY_ISSUER_ID" \
  --wait \
  --output-format json | tee "$SUBMIT_RESULT_PATH"
SUBMIT_EXIT_CODE="${PIPESTATUS[0]}"
set -e

SUBMISSION_ID="$(plutil -extract id raw -o - "$SUBMIT_RESULT_PATH" 2>/dev/null || true)"
SUBMISSION_STATUS="$(plutil -extract status raw -o - "$SUBMIT_RESULT_PATH" 2>/dev/null || true)"

if [[ -n "$SUBMISSION_ID" ]]; then
  set +e
  xcrun notarytool log "$SUBMISSION_ID" \
    --key "$API_KEY_PATH" \
    --key-id "$NOTARY_KEY_ID" \
    --issuer "$NOTARY_ISSUER_ID" \
    "$NOTARY_LOG_PATH"
  LOG_EXIT_CODE="$?"
  set -e

  if [[ -f "$NOTARY_LOG_PATH" ]]; then
    echo "Apple notarization log:"
    cat "$NOTARY_LOG_PATH"
  elif [[ "$LOG_EXIT_CODE" -ne 0 ]]; then
    echo "::warning::Could not download the Apple notarization log for submission $SUBMISSION_ID."
  fi
else
  echo "::warning::The notarization submission did not return a submission ID."
fi

if [[ "$SUBMIT_EXIT_CODE" -ne 0 ]]; then
  echo "::error::notarytool submit failed with exit code $SUBMIT_EXIT_CODE. Review the uploaded notarization diagnostics."
  exit "$SUBMIT_EXIT_CODE"
fi

if [[ "$SUBMISSION_STATUS" != "Accepted" ]]; then
  echo "::error::Apple notarization status is '${SUBMISSION_STATUS:-unknown}', not 'Accepted'. Submission ID: ${SUBMISSION_ID:-unknown}. Review the uploaded notarization diagnostics."
  exit 65
fi

xcrun stapler staple "$PACKAGE_PATH"
xcrun stapler validate "$PACKAGE_PATH"
spctl --assess --type install --verbose=4 "$PACKAGE_PATH"

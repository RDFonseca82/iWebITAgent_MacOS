#!/bin/bash
set -euo pipefail

if [[ "$#" -eq 0 ]]; then
  echo "Usage: validate-required-secrets.sh SECRET_NAME [...]" >&2
  exit 64
fi

missing_count=0
missing_names=""

for name in "$@"; do
  if [[ ! "$name" =~ ^[A-Z][A-Z0-9_]*$ ]]; then
    echo "Invalid environment variable name: $name" >&2
    exit 64
  fi

  if [[ -z "${!name:-}" ]]; then
    missing_count=$((missing_count + 1))
    missing_names="${missing_names}${missing_names:+ }${name}"
    echo "::error title=Missing Apple release secret::$name is empty. Configure it in the protected apple-release GitHub Environment."
  fi
done

if [[ "$missing_count" -gt 0 ]]; then
  printf 'Missing %d required Apple release secret(s): %s\n' \
    "$missing_count" "$missing_names" >&2
  exit 1
fi

echo "All required Apple release secrets are configured."

#!/usr/bin/env python3
import argparse
import base64
import json
from pathlib import Path
from urllib.parse import urlparse


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest-url", required=True)
    parser.add_argument("--key-id", required=True)
    parser.add_argument("--public-key-base64", required=True)
    parser.add_argument("--expected-team-id", required=True)
    parser.add_argument("--interval-seconds", type=int, default=21600)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    parsed = urlparse(args.manifest_url)
    if parsed.scheme.lower() != "https" or not parsed.netloc:
        parser.error("--manifest-url must be an absolute HTTPS URL")
    try:
        key = base64.b64decode(args.public_key_base64, validate=True)
    except ValueError as error:
        parser.error(f"invalid public key Base64: {error}")
    if len(key) != 32:
        parser.error("Ed25519 public key must contain exactly 32 bytes")
    if not args.key_id.strip():
        parser.error("--key-id cannot be empty")
    if not args.expected_team_id.isalnum():
        parser.error("--expected-team-id must be alphanumeric")
    if not 3600 <= args.interval_seconds <= 86400:
        parser.error("--interval-seconds must be between 3600 and 86400")

    document = {
        "schemaVersion": 1,
        "manifestURL": args.manifest_url,
        "updatePublicKeys": {args.key_id: args.public_key_base64},
        "expectedTeamID": args.expected_team_id,
        "checkIntervalSeconds": args.interval_seconds,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(document, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()

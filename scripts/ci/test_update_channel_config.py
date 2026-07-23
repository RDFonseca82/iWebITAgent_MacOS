#!/usr/bin/env python3
import base64
import json
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
GENERATOR = ROOT / "scripts" / "release" / "create-update-channel.py"


def run(*extra: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(GENERATOR), *extra],
        text=True,
        capture_output=True,
        check=False,
    )


def main() -> None:
    public_key = base64.b64encode(bytes(range(32))).decode("ascii")
    with tempfile.TemporaryDirectory() as directory:
        output = Path(directory) / "update-channel.json"
        result = run(
            "--manifest-url",
            "https://github.com/example/iwebit/releases/latest/download/update-manifest.json",
            "--key-id",
            "updates-2026",
            "--public-key-base64",
            public_key,
            "--expected-team-id",
            "R8VHDNRMJJ",
            "--interval-seconds",
            "21600",
            "--output",
            str(output),
        )
        assert result.returncode == 0, result.stderr
        document = json.loads(output.read_text(encoding="utf-8"))
        assert document["schemaVersion"] == 1
        assert document["updatePublicKeys"]["updates-2026"] == public_key
        assert document["checkIntervalSeconds"] == 21600

        insecure = run(
            "--manifest-url",
            "http://example.invalid/update-manifest.json",
            "--key-id",
            "updates-2026",
            "--public-key-base64",
            public_key,
            "--expected-team-id",
            "R8VHDNRMJJ",
            "--output",
            str(output),
        )
        assert insecure.returncode != 0

        short_key = run(
            "--manifest-url",
            "https://example.invalid/update-manifest.json",
            "--key-id",
            "updates-2026",
            "--public-key-base64",
            base64.b64encode(b"short").decode("ascii"),
            "--expected-team-id",
            "R8VHDNRMJJ",
            "--output",
            str(output),
        )
        assert short_key.returncode != 0

    print("Update channel configuration tests passed.")


if __name__ == "__main__":
    main()

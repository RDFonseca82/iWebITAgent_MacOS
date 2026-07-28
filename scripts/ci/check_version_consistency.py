#!/usr/bin/env python3

import json
import pathlib
import sys


ROOT = pathlib.Path(__file__).resolve().parents[2]
VERSION = json.loads((ROOT / "Configuration/version.json").read_text(encoding="utf-8"))
MARKETING = VERSION["marketingVersion"]
BUILD = VERSION["buildNumber"]

checks = {
    "Shared/Common/Constants.swift": [
        f'?? "{MARKETING}"',
        f'?? "{BUILD}"',
    ],
    "project-v2.yml": [
        f"MARKETING_VERSION: {MARKETING}",
        f"CURRENT_PROJECT_VERSION: {BUILD}",
    ],
    "iWebITMobile/project.yml": [
        f"MARKETING_VERSION: {MARKETING}",
        f"CURRENT_PROJECT_VERSION: {BUILD}",
    ],
    "iWebITAgent-macOS.xcodeproj/project.pbxproj": [
        f"MARKETING_VERSION = {MARKETING};",
        f"CURRENT_PROJECT_VERSION = {BUILD};",
    ],
    "iWebITInstaller/build.sh": [
        f'export VERSION="{MARKETING}"',
    ],
    ".github/workflows/apple-release.yml": [
        f"default: {MARKETING}",
        f"default: '{BUILD}'",
        "build_macos_app_store:",
        "if: inputs.build_macos_app_store",
        'PROVISIONING_PROFILE_SPECIFIER="$IOS_PROFILE_NAME"',
    ],
}

errors = []
for relative_path, expected_values in checks.items():
    text = (ROOT / relative_path).read_text(encoding="utf-8")
    for expected in expected_values:
        if expected not in text:
            errors.append(f"{relative_path}: missing {expected!r}")

legacy_version = "1.0.0.5"
for relative_path in checks:
    if legacy_version in (ROOT / relative_path).read_text(encoding="utf-8"):
        errors.append(f"{relative_path}: legacy version {legacy_version} remains")

if errors:
    print("\n".join(errors), file=sys.stderr)
    raise SystemExit(1)

print(f"All Apple agents use {MARKETING} ({BUILD}), release line {VERSION['releaseLine']}.")

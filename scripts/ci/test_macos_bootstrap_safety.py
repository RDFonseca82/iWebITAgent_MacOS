#!/usr/bin/env python3

from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def source(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


logger = source("Shared/Utilities/Logger.swift")
files_manager = source("Shared/Common/FilesManager.swift")
postinstall = source("scripts/release/package-scripts/postinstall")
project_spec = source("project-v2.yml")
package_builder = source("scripts/release/build-signed-package.sh")

important_branch = logger.index("if important")
verbose_lookup = logger.index("AppInfo.verbose")
if important_branch >= verbose_lookup:
    raise SystemExit(
        "Logger regression: important bootstrap errors initialize AppInfo recursively"
    )

if 'dataFolderName = "Data"' not in files_manager:
    raise SystemExit("FilesManager regression: mutable Data directory is missing")
expected_info_blocks = (
    "info:\n"
    "      path: iWebITAgent/Info.plist\n"
    "      properties:\n"
    "        CFBundleShortVersionString: $(MARKETING_VERSION)\n"
    "        CFBundleVersion: $(CURRENT_PROJECT_VERSION)",
    "info:\n"
    "      path: iWebITSysTray/Info.plist\n"
    "      properties:\n"
    "        CFBundleShortVersionString: $(MARKETING_VERSION)\n"
    "        CFBundleVersion: $(CURRENT_PROJECT_VERSION)",
)
for expected in expected_info_blocks:
    if expected not in project_spec:
        raise SystemExit(f"XcodeGen regression: missing app info block:\n{expected}")


data_setup = postinstall.index('mkdir -p "$DATA_DIR"')
agent_launch = postinstall.index("launchctl bootstrap system")
if data_setup >= agent_launch:
    raise SystemExit("Installer regression: processes launch before Data is prepared")

required_permissions = (
    'chown -R root:staff "$DATA_DIR"',
    'chmod 0770 "$DATA_DIR"',
)
for expected in required_permissions:
    if expected not in postinstall:
        raise SystemExit(f"Installer regression: missing {expected}")

version_check = package_builder.index(
    'validate_bundle_version "$INSTALL_DIR/iWebITAgent.app"'
)
signing = package_builder.index("resign_embedded_dylibs()")
if version_check >= signing:
    raise SystemExit("Package regression: bundle version is checked after signing")

print("macOS bootstrap safety tests passed.")

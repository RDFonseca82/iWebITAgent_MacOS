#!/usr/bin/env python3

from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def source(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


logger = source("Shared/Utilities/Logger.swift")
files_manager = source("Shared/Common/FilesManager.swift")
postinstall = source("scripts/release/package-scripts/postinstall")
preinstall = source("scripts/release/package-scripts/preinstall")
project_spec = source("project-v2.yml")
menu_bar = source("iWebITSysTray/MenuBarButton/MenuBarButton.swift")
package_builder = source("scripts/release/build-signed-package.sh")
menu_service = source("iWebITSysTray/MenuBarButton/MenuBarButtonService.swift")
async_networking = source("Shared/Utilities/NetworkingManager.swift")
sync_networking = source("iWebITService/Utils/NetworkingManagerExt.swift")

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
url_scheme_block = (
    "CFBundleURLTypes:\n"
    "          - CFBundleTypeRole: Editor\n"
    "            CFBundleURLName: app.iwebit.agent\n"
    "            CFBundleURLSchemes:\n"
    "              - iwebit"
)
if url_scheme_block not in project_spec:
    raise SystemExit("XcodeGen regression: iwebit URL scheme is missing")

launch_services_registration = postinstall.index(
    '"$LSREGISTER" -f "$PRODUCT_DIR/iWebIT.app"'
)
menu_bar_launch = postinstall.index(
    'launchctl bootstrap "gui/$CONSOLE_UID"'
)
if launch_services_registration >= menu_bar_launch:
    raise SystemExit(
        "Installer regression: URL scheme is registered after the menu bar starts"
    )

signing = package_builder.index("resign_embedded_dylibs()")
scheme_validation = package_builder.index(
    'validate_url_scheme "$INSTALL_DIR/iWebIT.app"'
)
if scheme_validation >= signing:
    raise SystemExit("Package regression: URL scheme is checked after signing")

required_fallbacks = ("[deepLinkURL]", "withApplicationAt: agentURL")
for expected in required_fallbacks:
    if expected not in menu_bar:
        raise SystemExit(f"Menu bar regression: missing URL fallback {expected}")

if "urlForApplication(toOpen:" in menu_bar:
    raise SystemExit(
        "Menu bar regression: routing trusts a possibly stale default URL handler"
    )



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

required_daemon_health_checks = (
    "launchctl kickstart -k system/app.iwebit.agent.service",
    'grep -q "state = running"',
    '[[ -f "$DATA_DIR/log_service.log" ]]',
    "daemon failed its post-install health check",
)
for expected in required_daemon_health_checks:
    if expected not in postinstall:
        raise SystemExit(f"Installer regression: missing daemon health check {expected}")

required_legacy_cleanup = (
    "unregister_and_remove_known_bundle",
    "Print :CFBundleIdentifier",
    "com.rdfonseca.iWebIT",
    "com.rdfonseca.iWebITSysTray",
    "/Applications/iWebIT.app",
    "/Applications/iWebITAgent.app",
    "com.rdfonseca.iWebITAgent",
)
for expected in required_legacy_cleanup:
    if expected not in preinstall:
        raise SystemExit(f"Preinstall regression: missing legacy cleanup {expected}")

for unsafe_target in ('rm -rf "$PRODUCT_DIR"', "DerivedData", 'rm -rf "$HOME"'):
    if unsafe_target in preinstall:
        raise SystemExit(f"Preinstall regression: unsafe cleanup target {unsafe_target}")

if 'app.iwebit.mobile' in preinstall:
    raise SystemExit("Preinstall regression: App Store bundle must be preserved")

if '"$PRODUCT_DIR/Data"' in preinstall:
    raise SystemExit("Preinstall regression: runtime Data must be preserved")

if '"$DATA_DIR/LegacyLogs"' not in postinstall:
    raise SystemExit("Installer regression: legacy logs are not migrated")

version_check = package_builder.index(
    'validate_bundle_version "$INSTALL_DIR/iWebITAgent.app"'
)
if version_check >= signing:
    raise SystemExit("Package regression: bundle version is checked after signing")

required_network_guards = (
    "import Network",
    "NWPathMonitor()",
    'AppInfo.uniqueid != "?"',
    "devicePollInFlight",
    "DEVICE POLL PAUSED: no network path",
    "DEVICE POLL PAUSED: registration has no UniqueID",
)
for expected in required_network_guards:
    if expected not in menu_service:
        raise SystemExit(f"Network diagnostics regression: missing {expected}")

if async_networking.count("request.timeoutInterval = 20") != 4:
    raise SystemExit("Async networking regression: every request needs a timeout")
if sync_networking.count("request.timeoutInterval = 20") != 3:
    raise SystemExit("Daemon networking regression: every request needs a timeout")
if sync_networking.count("semaphore.wait(timeout: .now() + 25)") != 3:
    raise SystemExit("Daemon networking regression: semaphore waits must be bounded")

print("macOS bootstrap safety tests passed.")

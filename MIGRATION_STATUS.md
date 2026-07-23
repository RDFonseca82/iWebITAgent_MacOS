# iWebIT Apple platform migration

## Implemented in this iteration

- All Apple agents and installers aligned to release line 2.0: marketing
  version 2.0.0, build 200, with runtime bundle reporting and CI consistency
  checks.
- Production legacy URLs changed to HTTPS and all legacy networking helpers
  reject non-HTTPS dynamic URLs.
- Unsigned legacy updates, destructive commands, remote location and remote
  screenshots are disabled by default.
- `iWebITCore` Swift Package with cross-platform snapshot models, typed legacy
  contracts, HTTPS-only API configuration, per-device HMAC authentication,
  Keychain storage, Ed25519 command verification, replay protection, verified
  updates, typed daemon state, enrollment/support APIs and mobile privacy checks.
- Fixture and opt-in live backend contract tests.
- macOS v2 telemetry, signed-command dispatch for restart/shutdown, allowlisted
  app removal, consented screenshot/location and verified `.pkg` installation.
- Restricted macOS XPC protocol with code-signing requirements.
- Universal iPhone/iPad SwiftUI app for iOS/iPadOS 15+ with secure enrollment,
  adaptive navigation, support/incidents, APNs wake-up, background refresh and
  app-only device synchronization through public APIs.
- One-shot mobile location synchronization, started visibly by the user and
  guarded by the system When In Use permission.
- Privacy-safe schema 2.0 examples for macOS, iOS and iPadOS.
- XcodeGen project specifications, GitHub Actions CI, an immutable GitHub
  Release channel for verified macOS auto-update, and optional App Store
  Connect/TestFlight upload for the signed universal IPA.

## Deliberate platform boundaries

No device-management service, enrollment profile, supervision workflow or
administrative mobile command is part of this version. On iPhone and iPad:

- restart, shutdown and removal of other apps are unavailable;
- silent arbitrary screenshots are unavailable;
- updates use the App Store or TestFlight;
- location is one-shot and user initiated;
- inventory is limited to information exposed to a normal application by
  public Apple APIs and allowed for off-device synchronization.

The secure macOS handlers remain unreachable from unsigned legacy flags.
Activation requires the backend v2 command queue, public-key enrollment,
operator authorization and audit-result endpoints. Do not re-enable the legacy
command flags.

## External prerequisites

- Implement `/v2/enrollments`, authenticated snapshot/support/push-token
  endpoints, nonce storage and signed macOS command delivery.
- Generate separate offline-controlled Ed25519 keys for macOS commands and
  updates.
- Configure APNs keys/topics and production mobile entitlements.
- Provide Developer ID Application and Installer certificates plus a
  `notarytool` Keychain profile.
- Provide Apple Development/Distribution signing and provisioning profiles for
  iPhone/iPad builds distributed through TestFlight or the App Store.
- Confirm final Team ID and bundle identifiers.
- Complete legal/privacy review, retention periods and employee/customer
  notices.

## Validation status

JSON examples, plist files, entitlements and the Privacy Manifest pass local
syntax validation. `git diff --check` passes.

This workspace runs on Windows and has no Swift/Xcode toolchain. Swift
compilation, XCTest, XcodeGen validation, simulator builds, macOS builds,
signing and notarization run on GitHub-hosted macOS runners. Installation-ready
artifacts require the Apple signing certificates, provisioning material and
notarization credentials configured as GitHub secrets.
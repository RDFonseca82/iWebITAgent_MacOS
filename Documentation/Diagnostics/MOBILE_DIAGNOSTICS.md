# Mobile agent diagnostics

The iOS/iPadOS app contains a **Diagnostic** destination for local troubleshooting.
Opening it and signing out both require the same IDSYNC used during enrollment.

## Access control

The production backend currently requires IDSYNC on every Apple registration and
synchronization. The app therefore stores IDSYNC only in the device Keychain,
together with the installation identifier and company identifier, using
`AfterFirstUnlockThisDeviceOnly`. It is never written to UserDefaults, files or
logs and is not synchronized through iCloud Keychain.

For local diagnostic/logout authorization, the app separately stores a salted
SHA-256 verifier and compares attempts in constant time. Failed attempts never
include the submitted code in logs. After five failed attempts, protected
actions are blocked for 60 seconds.

Enrollment first verifies the company over HTTPS with
`script_api.php?IdSync=...`, then registers the device by posting the exact
legacy form contract (`json=<JSON>`) to `script_ios.php`. All later Apple device
synchronizations use the same `script_ios.php` endpoint. Protected logout deletes
the Keychain credentials, the local verifier, last-sync state and logs.

## Information displayed

The diagnostic report is generated only after authorization and includes:

- app version/build, bundle identifier and configured synchronization endpoint;
- installation device ID (but never IDSYNC);
- last successful synchronization and last result;
- APNs registration state;
- device name/model/vendor identifier, OS/kernel, locale and timezone;
- architecture, CPU counts, physical memory and battery level;
- network transport, constrained/expensive state, local addresses and public IP;
- notification, location and background-refresh authorization;
- recent protected agent logs.

Local and public IP values are displayed locally. The first locally visible
address may be sent as the legacy `DeviceHost` field; the public-IP lookup result
is not added to the JSON sent to `script_ios.php`. The public IP is resolved over
HTTPS using `IWebITPublicIPAddressURL`, currently
`https://api64.ipify.org?format=json`. That provider necessarily observes the
source IP of the request. Replace it with an iWebIT endpoint if third-party lookup
is not acceptable.

## Logs

Feature-level actions are recorded for lifecycle, enrollment, synchronization,
support, location, APNs, background refresh, diagnostics, authorization and
logout. Logs deliberately exclude:

- IDSYNC values and hashes;
- Keychain contents and APNs tokens;
- support message contents;
- precise coordinates and IP values.

Logs are JSON Lines files in Application Support with
`completeUntilFirstUserAuthentication` data protection. The current file rotates
at 512 KiB and one previous file is retained. The diagnostic UI loads at most 500
recent entries and can copy their redacted text.
# Mobile agent diagnostics

The iOS/iPadOS app contains a **Diagnostic** destination for local troubleshooting.
Opening it and signing out both require the same IDSYNC used during enrollment.

## Access control

The app never stores the IDSYNC as plain text. After a successful enrollment it:

1. generates a random 32-byte salt;
2. hashes the normalized IDSYNC and salt with SHA-256;
3. stores only the salt and digest in the device Keychain using
   `AfterFirstUnlockThisDeviceOnly`;
4. compares future attempts in constant time.

An installation upgraded from an earlier version has no verifier. Its first
protected action validates IDSYNC using the HTTPS enrollment endpoint, rotates
the device credentials, stores the verifier, and then authorizes the action.
Failed attempts never include the submitted code in logs. After five failed
attempts, protected actions are blocked for 60 seconds to limit local and online
guessing.

Protected logout deletes device credentials, server trust, the IDSYNC verifier,
last-sync state, and logs from the previous association.

## Information displayed

The diagnostic report is generated only after authorization and includes:

- app version/build, bundle identifier and configured API endpoint;
- server-issued device ID and key ID, but never the shared secret;
- last successful synchronization and last result;
- APNs registration state;
- device name/model/vendor identifier, OS/kernel, locale and timezone;
- architecture, CPU counts, physical memory and battery level;
- network transport, constrained/expensive state, local addresses and public IP;
- notification, location and background-refresh authorization;
- recent protected agent logs.

Local and public IP values are displayed locally and are not added to the device
snapshot sent to `/v2/devices/snapshots`. The public IP is resolved over HTTPS
using the URL in `IWebITPublicIPAddressURL`, currently
`https://api64.ipify.org?format=json`. That provider necessarily observes the
source IP of the request. Replace the configuration with an equivalent iWebIT
backend endpoint before production if third-party lookup is not acceptable.

## Logs

Feature-level actions are recorded for lifecycle, enrollment, synchronization,
support, location, APNs, background refresh, diagnostics, authorization and
logout. Logs deliberately exclude:

- IDSYNC values and hashes;
- shared secrets, API signatures and APNs tokens;
- support message contents;
- precise coordinates and IP values.

Logs are JSON Lines files in Application Support with
`completeUntilFirstUserAuthentication` data protection. The current file
rotates at 512 KiB and one previous file is retained. The diagnostic UI loads at
most 500 recent entries and can copy their redacted text.

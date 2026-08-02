# Device synchronization examples

These files use schema `2.0` from `iWebITCore` and fictional identifiers.

- `macos.json` shows the richer data available to the full macOS agent.
- `macos-app-store.json` shows the privacy-limited snapshot from the sandboxed Mac App Store edition.
- `ios.json` shows an app-only iPhone snapshot after the user explicitly chose
  to synchronize location.
- `ipados.json` shows an app-only iPad snapshot with location denied.

The macOS App Store, iOS and iPadOS examples intentionally omit serial number, application and
service inventory, security posture, uptime and disk values. Empty objects and
arrays are preserved where required by the common schema. `collection` records
why unavailable fields were not collected.

## Transport used in production

The files above document the complete internal schema before transport. For all
Apple targets, that snapshot is mapped to the legacy Apple payload and sent over
HTTPS as an `application/x-www-form-urlencoded` POST with a single `json` field:

```text
POST https://agent.iwebit.app/scripts/script_ios.php
Content-Type: application/x-www-form-urlencoded; charset=utf-8

json=<percent-encoded JSON object>
```

The wire JSON keeps the established fields (`TypeSync`, `UniqueID`, `IDSync`,
`IdCompany`, `IdDeviceType`, `AppleType`, hardware and location fields) and adds
available schema 2.0 diagnostics, APNs state, permissions and collection results.
`AppleType` is `1` for macOS and `2` for iOS/iPadOS. Registration is the first
full synchronization to this same endpoint; there is no separate Apple
registration URL.

Before posting, the app reads company information through
`script_api.php?IdSync=...`. Support reads use `script_api.php` and support writes
use `script_api_support.php`; neither replaces the synchronization endpoint.
Never use the example values as production identifiers or credentials.
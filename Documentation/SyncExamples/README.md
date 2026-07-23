# Device synchronization examples

These files use schema `2.0` from `iWebITCore` and fictional identifiers.

- `macos.json` shows the richer data available to the macOS agent.
- `ios.json` shows an app-only iPhone snapshot after the user explicitly chose
  to synchronize location.
- `ipados.json` shows an app-only iPad snapshot with location denied.

The iOS/iPadOS examples intentionally omit serial number, application and
service inventory, security posture, uptime and disk values. Empty objects and
arrays are preserved where required by the common schema. `collection` records
why unavailable fields were not collected.

Never use the example values as production identifiers or credentials.
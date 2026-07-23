# Apple remote capability matrix

The supported baseline is macOS 11+, iOS 15+ and iPadOS 15+. The iPhone/iPad
product is a normal app and contains no device-management functionality.
Production policy should still block destructive or privacy-sensitive macOS
commands on operating systems that no longer receive Apple security fixes.

| Capability | macOS 11+ agent | iOS/iPadOS 15+ app |
|---|---|---|
| Update | Signed/notarized `.pkg` | App Store or TestFlight |
| Restart | Privileged signed daemon | Unavailable |
| Shutdown | Privileged signed daemon | Unavailable |
| Remove another app | Allowlisted `/Applications/*.app` bundle | Unavailable |
| Screenshot | Logged-in agent plus Screen Recording permission | Unavailable; arbitrary remote capture is prohibited |
| Location | Logged-in agent plus Location permission | One-shot in-app request with visible action and consent |
| Device synchronization | Privileged/public macOS APIs | Public app APIs and privacy-safe off-device fields only |

Relevant Apple platform references:

- [UIDevice](https://developer.apple.com/documentation/uikit/uidevice)
- [Core Location authorization](https://developer.apple.com/documentation/corelocation/requesting-authorization-to-use-location-services)
- [Required Reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)
- [ReplayKit](https://developer.apple.com/documentation/replaykit)
- [ScreenCaptureKit](https://developer.apple.com/documentation/screencapturekit)

## Legacy protocol mapping

The old backend flags are not re-enabled. For macOS only, backend intentions
map to short-lived signed commands for verified pkg installation, restart,
shutdown, allowlisted app removal, consented screen capture and consented
location.

Each Mac verifies the target device ID, Ed25519 signature, key ID, activation
and expiry times, and nonce before dispatch. Replays and unknown commands are
rejected. Destructive work runs only in the privileged daemon; privacy-sensitive
work runs only in the signed logged-in agent.

On iPhone and iPad, APNs and background refresh may request a normal snapshot
sync. They do not authorize or execute administrative commands, do not request
location automatically and do not bypass user or system permissions.
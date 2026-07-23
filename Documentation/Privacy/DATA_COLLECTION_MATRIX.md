# Data collection matrix

This is a technical inventory for the app-only implementation. It is not a
substitute for legal review or the App Store Connect privacy questionnaire.

| Category | macOS agent | iOS/iPadOS app | Mobile notes |
|---|---|---|---|
| Enrollment device ID | Yes | Yes | Server-issued identifier; authenticate every request |
| Display name, device family and machine identifier | Yes | Yes | Public APIs; the user can change the display name |
| Vendor identifier (IDFV) | No | Yes | May change after all vendor apps are removed |
| OS name/version, kernel, locale and timezone | Yes | Yes | Public runtime information |
| CPU counts, architecture and physical memory | Yes | Yes | Public process/system APIs |
| Battery level/state and Low Power Mode | Yes | Yes | Battery monitoring is enabled by the app |
| Network transport, constrained/expensive state | Yes | Yes | No Wi-Fi SSID, BSSID, MAC address or IP inventory on mobile |
| Notification, location and background-refresh authorization | Yes | Yes | Authorization state only |
| Agent version/build, last sync and push-token availability | Yes | Yes | Push-token contents are sent only to the dedicated token endpoint |
| Location | With permission | One-shot, user initiated | No silent or continuous mobile tracking |
| Serial number | Yes | No | Not exposed to a normal iOS/iPadOS app |
| Installed applications | Yes | No | Never infer with private APIs |
| Services/processes | Yes | No | Privileged macOS agent only |
| Disk capacity | Yes | Not uploaded | Periodic off-device use conflicts with Required Reason API purposes |
| System uptime/boot time | Yes | Not uploaded | Required Reason API restrictions apply |
| Security/passcode/encryption posture | Yes where supported | No | Not exposed to a normal mobile app |
| Screenshot | Explicit macOS permission | User-created support attachment only | No silent arbitrary capture |

Unavailable mobile fields remain empty and have a corresponding `collection`
entry explaining whether they are unavailable, unsupported or denied. Location
is included only in the snapshot immediately following the user's explicit
request, then the cached coordinate is cleared.

Retention, access control, deletion, user notice, lawful basis and incident
response must be approved before production collection is enabled.
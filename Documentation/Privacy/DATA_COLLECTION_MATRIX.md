# Data collection matrix

This is a technical inventory for the app-only implementations. It is not a
substitute for legal review or the App Store Connect privacy questionnaire.

| Category | Full macOS pkg agent | macOS App Store | iOS/iPadOS app |
|---|---|---|---|
| Enrollment device ID | Yes | Yes | Yes |
| Display name, device family and machine identifier | Yes | Yes | Yes |
| Vendor identifier (IDFV) | No | No | Yes |
| OS name/version, kernel, locale and timezone | Yes | Yes | Yes |
| CPU counts, architecture and physical memory | Yes | Yes | Yes |
| Battery level/state and Low Power Mode | Yes | No | Yes |
| Network overview | Interfaces and addresses | Host name only | Transport state only |
| Notification authorization | Yes | Yes | Yes |
| Background sync | Daemon schedule | APNs on demand | APNs and BackgroundTasks |
| Agent version/build, last sync and push availability | Yes | Yes | Yes |
| Support tickets | Yes | Yes | Yes |
| Location | With explicit permission/legacy request | No | One-shot, user initiated |
| Serial number | Yes | No | No |
| Installed applications | Yes | No | No |
| Services/processes | Yes | No | No |
| Disk capacity | Yes | No | Not uploaded |
| System uptime/boot time | Yes | No | Not uploaded |
| Security/encryption posture | Yes where supported | No | No |
| Screenshot | Explicit macOS permission | No | User-created support attachment only |
| Remote restart/shutdown/application removal | Signed command | No | No |
| Update delivery | Verified signed GitHub pkg | Mac App Store | App Store/TestFlight |

The Mac App Store edition is sandboxed and uses only application-origin data.
Its runtime validates every snapshot before upload and rejects privileged source
markers, disk/uptime values, serial number, application/service inventory,
security posture and location.

Unavailable fields remain empty and have a corresponding `collection` entry
explaining whether they are unavailable, unsupported, denied or not managed.
Mobile location is included only in the snapshot immediately following the
user's explicit request, then the cached coordinate is cleared.

Retention, access control, deletion, user notice, lawful basis and incident
response must be approved before production collection is enabled.

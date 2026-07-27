import Darwin
import Foundation
import iWebITCore
import UserNotifications

struct MacStoreDeviceCollector: Sendable {
    @MainActor
    func collect(
        deviceID: String,
        lastSuccessfulSyncAt: Date?,
        pushTokenAvailable: Bool
    ) async throws -> DeviceSnapshot {
        let process = ProcessInfo.processInfo
        let notificationAuthorization = await notificationAuthorizationDescription()

        return DeviceSnapshot(
            platform: .macOS,
            identity: DeviceIdentity(
                deviceID: deviceID,
                displayName: Host.current().localizedName,
                model: "Mac",
                modelIdentifier: sysctlString("hw.model")
            ),
            operatingSystem: OperatingSystemInfo(
                name: "macOS",
                version: operatingSystemVersion(process.operatingSystemVersion),
                kernelVersion: kernelVersion(),
                locale: Locale.current.identifier,
                timeZone: TimeZone.current.identifier,
                uptimeSeconds: nil
            ),
            hardware: HardwareInfo(
                architecture: machineIdentifier(),
                processor: nil,
                processorCount: process.processorCount,
                activeProcessorCount: process.activeProcessorCount,
                physicalMemoryBytes: process.physicalMemory
            ),
            storage: StorageInfo(),
            battery: nil,
            network: NetworkInfo(hostName: process.hostName),
            security: SecurityInfo(),
            management: ManagementInfo(isManaged: false),
            agent: AgentInfo(
                version: Bundle.main.object(
                    forInfoDictionaryKey: "CFBundleShortVersionString"
                ) as? String ?? "0",
                build: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0",
                bundleIdentifier: Bundle.main.bundleIdentifier ?? "app.iwebit.mobile",
                lastSuccessfulSyncAt: lastSuccessfulSyncAt,
                pushTokenAvailable: pushTokenAvailable,
                backgroundRefreshStatus: "apns-on-demand"
            ),
            location: nil,
            permissions: [
                PermissionInfo(
                    capability: "notifications",
                    authorization: notificationAuthorization,
                    required: true
                )
            ],
            collection: [
                CollectionResult(category: "identity", state: .collected, source: .application),
                CollectionResult(category: "operatingSystem", state: .collected, source: .application),
                CollectionResult(category: "hardware", state: .collected, source: .application),
                CollectionResult(category: "network", state: .collected, source: .application),
                CollectionResult(
                    category: "notifications",
                    state: notificationAuthorization == "authorized" ? .collected : .permissionDenied,
                    source: .application
                ),
                CollectionResult(
                    category: "storage",
                    state: .unsupported,
                    source: .application,
                    message: "Excluded from the sandboxed App Store edition."
                ),
                CollectionResult(
                    category: "location",
                    state: .unsupported,
                    source: .application,
                    message: "Location is not collected by the macOS App Store edition."
                ),
                CollectionResult(
                    category: "applications",
                    state: .unsupported,
                    source: .application,
                    message: "Application inventory requires the separately distributed full agent."
                ),
                CollectionResult(
                    category: "services",
                    state: .unsupported,
                    source: .application,
                    message: "Service inventory requires the separately distributed full agent."
                ),
                CollectionResult(
                    category: "security",
                    state: .unsupported,
                    source: .application,
                    message: "Privileged security posture is excluded from the App Store edition."
                ),
                CollectionResult(category: "management", state: .notManaged, source: .application)
            ]
        )
    }

    private func notificationAuthorizationDescription() async -> String {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                let description: String
                switch settings.authorizationStatus {
                case .notDetermined:
                    description = "notDetermined"
                case .denied:
                    description = "denied"
                case .authorized:
                    description = "authorized"
                case .provisional:
                    description = "provisional"
                @unknown default:
                    description = "unknown"
                }
                continuation.resume(returning: description)
            }
        }
    }

    private func operatingSystemVersion(_ version: OperatingSystemVersion) -> String {
        "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    private func machineIdentifier() -> String {
        var info = utsname()
        uname(&info)
        let capacity = MemoryLayout.size(ofValue: info.machine)
        return withUnsafePointer(to: &info.machine) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: capacity) {
                String(cString: $0)
            }
        }
    }

    private func kernelVersion() -> String? {
        var info = utsname()
        guard uname(&info) == 0 else { return nil }
        let capacity = MemoryLayout.size(ofValue: info.release)
        return withUnsafePointer(to: &info.release) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: capacity) {
                String(cString: $0)
            }
        }
    }

    private func sysctlString(_ name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var value = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &value, &size, nil, 0) == 0 else { return nil }
        return String(cString: value)
    }
}

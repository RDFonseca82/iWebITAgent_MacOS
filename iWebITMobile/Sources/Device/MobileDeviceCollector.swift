import CoreLocation
import Foundation
import iWebITCore
import UIKit
import UserNotifications

struct MobileDeviceCollector: Sendable {
    @MainActor
    func collect(
        deviceID: String,
        lastSuccessfulSyncAt: Date?,
        pushTokenAvailable: Bool
    ) async throws -> DeviceSnapshot {
        UIDevice.current.isBatteryMonitoringEnabled = true

        let device = UIDevice.current
        let process = ProcessInfo.processInfo
        let platform: ApplePlatform = device.userInterfaceIdiom == .pad ? .iPadOS : .iOS
        let network = MobileNetworkMonitor.shared.current()
        let notificationAuthorization = await notificationAuthorizationDescription()
        let locationProvider = MobileLocationProvider.shared
        let locationAuthorization = locationProvider.authorizationDescription
        let location = locationProvider.latestAuthorizedLocation.map {
            LocationInfo(
                latitude: $0.coordinate.latitude,
                longitude: $0.coordinate.longitude,
                horizontalAccuracyMeters: max(0, $0.horizontalAccuracy),
                altitudeMeters: $0.verticalAccuracy >= 0 ? $0.altitude : nil,
                recordedAt: $0.timestamp,
                authorization: locationAuthorization
            )
        }

        return DeviceSnapshot(
            platform: platform,
            identity: DeviceIdentity(
                deviceID: deviceID,
                displayName: device.name,
                model: device.model,
                modelIdentifier: machineIdentifier(),
                vendorIdentifier: device.identifierForVendor
            ),
            operatingSystem: OperatingSystemInfo(
                name: device.systemName,
                version: device.systemVersion,
                kernelVersion: kernelVersion(),
                locale: Locale.current.identifier,
                timeZone: TimeZone.current.identifier,
                uptimeSeconds: nil
            ),
            hardware: HardwareInfo(
                architecture: architecture(),
                processorCount: process.processorCount,
                activeProcessorCount: process.activeProcessorCount,
                physicalMemoryBytes: process.physicalMemory
            ),
            storage: StorageInfo(),
            battery: BatteryInfo(
                level: device.batteryLevel >= 0 ? Double(device.batteryLevel) : nil,
                state: batteryState(device.batteryState),
                isLowPowerModeEnabled: process.isLowPowerModeEnabled
            ),
            network: network.info,
            security: SecurityInfo(),
            management: ManagementInfo(isManaged: false),
            agent: AgentInfo(
                version: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0",
                build: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0",
                bundleIdentifier: Bundle.main.bundleIdentifier ?? "app.iwebit.mobile",
                lastSuccessfulSyncAt: lastSuccessfulSyncAt,
                pushTokenAvailable: pushTokenAvailable,
                backgroundRefreshStatus: UIApplication.shared.backgroundRefreshStatus.description
            ),
            location: location,
            permissions: [
                PermissionInfo(capability: "location", authorization: locationAuthorization, required: false),
                PermissionInfo(capability: "notifications", authorization: notificationAuthorization, required: true),
                PermissionInfo(
                    capability: "backgroundRefresh",
                    authorization: UIApplication.shared.backgroundRefreshStatus.description,
                    required: true
                )
            ],
            collection: collectionResults(
                networkAvailable: network.isAvailable,
                location: location,
                locationAuthorization: locationAuthorization
            )
        )
    }

    private func collectionResults(
        networkAvailable: Bool,
        location: LocationInfo?,
        locationAuthorization: String
    ) -> [CollectionResult] {
        let locationState: CollectionState
        if location != nil {
            locationState = .collected
        } else if locationAuthorization == "denied" || locationAuthorization == "restricted" {
            locationState = .permissionDenied
        } else {
            locationState = .unavailable
        }

        return [
            CollectionResult(category: "identity", state: .collected, source: .application),
            CollectionResult(category: "operatingSystem", state: .collected, source: .application),
            CollectionResult(category: "hardware", state: .collected, source: .application),
            CollectionResult(category: "battery", state: .collected, source: .application),
            CollectionResult(
                category: "network",
                state: networkAvailable ? .collected : .unavailable,
                source: .application
            ),
            CollectionResult(
                category: "storage",
                state: .unavailable,
                source: .application,
                message: "Automatic off-device disk telemetry is excluded by Apple Required Reason API policy."
            ),
            CollectionResult(category: "location", state: locationState, source: .user),
            CollectionResult(
                category: "applications",
                state: .unsupported,
                source: .application,
                message: "iOS and iPadOS do not expose installed application inventory to applications."
            ),
            CollectionResult(
                category: "services",
                state: .unsupported,
                source: .application,
                message: "iOS and iPadOS do not expose system services to applications."
            ),
            CollectionResult(
                category: "security",
                state: .unsupported,
                source: .application,
                message: "Passcode, encryption and system security posture are not exposed to applications."
            )
        ]
    }

    private func notificationAuthorizationDescription() async -> String {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                let value: String
                switch settings.authorizationStatus {
                case .notDetermined: value = "notDetermined"
                case .denied: value = "denied"
                case .authorized: value = "authorized"
                case .provisional: value = "provisional"
                case .ephemeral: value = "ephemeral"
                @unknown default: value = "unknown"
                }
                continuation.resume(returning: value)
            }
        }
    }

    private func batteryState(_ state: UIDevice.BatteryState) -> String? {
        switch state {
        case .unknown: return nil
        case .unplugged: return "unplugged"
        case .charging: return "charging"
        case .full: return "full"
        @unknown default: return nil
        }
    }

    private func machineIdentifier() -> String? {
        var systemInfo = utsname()
        uname(&systemInfo)
        let value = tupleString(systemInfo.machine)
        return value.isEmpty ? nil : value
    }

    private func kernelVersion() -> String? {
        var systemInfo = utsname()
        uname(&systemInfo)
        let value = tupleString(systemInfo.release)
        return value.isEmpty ? nil : value
    }

    private func tupleString<T>(_ tuple: T) -> String {
        Mirror(reflecting: tuple).children.reduce(into: "") { value, element in
            guard let byte = element.value as? Int8, byte != 0 else { return }
            value.append(Character(UnicodeScalar(UInt8(byte))))
        }
    }

    private func architecture() -> String {
        #if arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #else
        return "unknown"
        #endif
    }
}

private extension UIBackgroundRefreshStatus {
    var description: String {
        switch self {
        case .available: return "available"
        case .denied: return "denied"
        case .restricted: return "restricted"
        @unknown default: return "unknown"
        }
    }
}
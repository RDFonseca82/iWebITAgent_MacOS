import XCTest
@testable import iWebITCore

final class PrivacyTests: XCTestCase {
    func testRejectsDiskTelemetryFromMobileApplication() {
        let snapshot = mobileSnapshot(
            storage: StorageInfo(totalBytes: 100, availableBytes: 50),
            uptime: nil
        )
        XCTAssertThrowsError(try SnapshotPrivacyValidator().validateMobileAppOrigin(snapshot)) {
            XCTAssertEqual($0 as? SnapshotPrivacyViolation, .mobileDiskTelemetry)
        }
    }

    func testRejectsUptimeTelemetryFromMobileApplication() {
        let snapshot = mobileSnapshot(storage: StorageInfo(), uptime: 42)
        XCTAssertThrowsError(try SnapshotPrivacyValidator().validateMobileAppOrigin(snapshot)) {
            XCTAssertEqual($0 as? SnapshotPrivacyViolation, .mobileUptimeTelemetry)
        }
    }

    func testAcceptsMinimizedMobileSnapshot() {
        let snapshot = mobileSnapshot(storage: StorageInfo(), uptime: nil)
        XCTAssertNoThrow(try SnapshotPrivacyValidator().validateMobileAppOrigin(snapshot))
    }

    func testAcceptsSandboxedMacAppStoreSnapshot() {
        XCTAssertNoThrow(
            try SnapshotPrivacyValidator().validateMacAppStoreOrigin(macStoreSnapshot())
        )
    }

    func testRejectsPrivilegedSourceFromMacAppStore() {
        let snapshot = macStoreSnapshot(
            collection: [
                CollectionResult(category: "security", state: .collected, source: .privilegedAgent)
            ]
        )
        XCTAssertThrowsError(try SnapshotPrivacyValidator().validateMacAppStoreOrigin(snapshot)) {
            XCTAssertEqual($0 as? SnapshotPrivacyViolation, .macAppStorePrivilegedSource)
        }
    }

    func testRejectsApplicationInventoryFromMacAppStore() {
        let snapshot = macStoreSnapshot(
            applications: [InstalledApplication(name: "Example", source: .application)]
        )
        XCTAssertThrowsError(try SnapshotPrivacyValidator().validateMacAppStoreOrigin(snapshot)) {
            XCTAssertEqual($0 as? SnapshotPrivacyViolation, .macAppStoreApplicationInventory)
        }
    }

    private func mobileSnapshot(storage: StorageInfo, uptime: TimeInterval?) -> DeviceSnapshot {
        DeviceSnapshot(
            platform: .iOS,
            identity: DeviceIdentity(deviceID: "device-1", model: "iPhone"),
            operatingSystem: OperatingSystemInfo(
                name: "iOS",
                version: "26.0",
                locale: "pt_PT",
                timeZone: "Europe/Lisbon",
                uptimeSeconds: uptime
            ),
            hardware: HardwareInfo(
                architecture: "arm64",
                processorCount: 6,
                activeProcessorCount: 6,
                physicalMemoryBytes: 8_000_000_000
            ),
            storage: storage,
            battery: nil,
            network: NetworkInfo(),
            security: SecurityInfo(),
            management: ManagementInfo(isManaged: false),
            agent: AgentInfo(
                version: "2.0.0",
                build: "200",
                bundleIdentifier: "app.iwebit.mobile",
                pushTokenAvailable: false
            ),
            location: nil
        )
    }

    private func macStoreSnapshot(
        applications: [InstalledApplication] = [],
        collection: [CollectionResult] = []
    ) -> DeviceSnapshot {
        DeviceSnapshot(
            platform: .macOS,
            identity: DeviceIdentity(
                deviceID: "mac-store-1",
                displayName: "Mac",
                model: "Mac",
                modelIdentifier: "arm64"
            ),
            operatingSystem: OperatingSystemInfo(
                name: "macOS",
                version: "15.0",
                locale: "pt_PT",
                timeZone: "Europe/Lisbon"
            ),
            hardware: HardwareInfo(
                architecture: "arm64",
                processorCount: 8,
                activeProcessorCount: 8,
                physicalMemoryBytes: 16_000_000_000
            ),
            storage: StorageInfo(),
            battery: nil,
            network: NetworkInfo(hostName: "Mac"),
            security: SecurityInfo(),
            management: ManagementInfo(isManaged: false),
            agent: AgentInfo(
                version: "2.0.0",
                build: "200",
                bundleIdentifier: "app.iwebit.mobile",
                pushTokenAvailable: true,
                backgroundRefreshStatus: "push"
            ),
            location: nil,
            applications: applications,
            collection: collection
        )
    }
}

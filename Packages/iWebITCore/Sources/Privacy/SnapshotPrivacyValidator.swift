import Foundation

public enum SnapshotPrivacyViolation: Error, Equatable {
    case mobileDiskTelemetry
    case mobileUptimeTelemetry
    case mobileSerialNumber
    case mobileApplicationInventory
    case mobileServiceInventory
    case mobileSecurityPosture
    case locationWithoutAuthorization
    case macAppStoreDiskTelemetry
    case macAppStoreUptimeTelemetry
    case macAppStoreSerialNumber
    case macAppStoreApplicationInventory
    case macAppStoreServiceInventory
    case macAppStoreSecurityPosture
    case macAppStoreLocation
    case macAppStorePrivilegedSource
}

public struct SnapshotPrivacyValidator: Sendable {
    public init() {}

    /// Validates a snapshot produced directly by the iOS/iPadOS application.
    /// The mobile app is the only source; unavailable platform data must remain empty.
    public func validateMobileAppOrigin(_ snapshot: DeviceSnapshot) throws {
        guard snapshot.platform == .iOS || snapshot.platform == .iPadOS else {
            return
        }
        if snapshot.storage.totalBytes != nil ||
            snapshot.storage.availableBytes != nil ||
            snapshot.storage.importantUsageAvailableBytes != nil ||
            snapshot.storage.opportunisticUsageAvailableBytes != nil {
            throw SnapshotPrivacyViolation.mobileDiskTelemetry
        }
        if snapshot.operatingSystem.uptimeSeconds != nil {
            throw SnapshotPrivacyViolation.mobileUptimeTelemetry
        }
        if snapshot.identity.serialNumber != nil {
            throw SnapshotPrivacyViolation.mobileSerialNumber
        }
        if !snapshot.applications.isEmpty {
            throw SnapshotPrivacyViolation.mobileApplicationInventory
        }
        if !snapshot.services.isEmpty {
            throw SnapshotPrivacyViolation.mobileServiceInventory
        }
        if snapshot.security.isPasscodePresent != nil ||
            snapshot.security.isEncrypted != nil ||
            snapshot.security.secureBootLevel != nil ||
            snapshot.security.activationLockEnabled != nil {
            throw SnapshotPrivacyViolation.mobileSecurityPosture
        }
        if let location = snapshot.location,
           !location.authorization.lowercased().contains("authorized") {
            throw SnapshotPrivacyViolation.locationWithoutAuthorization
        }
    }

    /// Validates telemetry produced by the sandboxed Mac App Store edition.
    /// Privileged or broad device-management information belongs only to the
    /// separately distributed Developer ID agent.
    public func validateMacAppStoreOrigin(_ snapshot: DeviceSnapshot) throws {
        guard snapshot.platform == .macOS else { return }
        if snapshot.storage.totalBytes != nil ||
            snapshot.storage.availableBytes != nil ||
            snapshot.storage.importantUsageAvailableBytes != nil ||
            snapshot.storage.opportunisticUsageAvailableBytes != nil {
            throw SnapshotPrivacyViolation.macAppStoreDiskTelemetry
        }
        if snapshot.operatingSystem.uptimeSeconds != nil {
            throw SnapshotPrivacyViolation.macAppStoreUptimeTelemetry
        }
        if snapshot.identity.serialNumber != nil {
            throw SnapshotPrivacyViolation.macAppStoreSerialNumber
        }
        if !snapshot.applications.isEmpty {
            throw SnapshotPrivacyViolation.macAppStoreApplicationInventory
        }
        if !snapshot.services.isEmpty {
            throw SnapshotPrivacyViolation.macAppStoreServiceInventory
        }
        if snapshot.security.isPasscodePresent != nil ||
            snapshot.security.isEncrypted != nil ||
            snapshot.security.secureBootLevel != nil ||
            snapshot.security.systemIntegrityProtectionEnabled != nil ||
            snapshot.security.firewallEnabled != nil ||
            snapshot.security.gatekeeperEnabled != nil ||
            snapshot.security.activationLockEnabled != nil ||
            snapshot.security.compromised != nil {
            throw SnapshotPrivacyViolation.macAppStoreSecurityPosture
        }
        if snapshot.location != nil {
            throw SnapshotPrivacyViolation.macAppStoreLocation
        }
        if snapshot.collection.contains(where: { $0.source == .privilegedAgent }) {
            throw SnapshotPrivacyViolation.macAppStorePrivilegedSource
        }
    }
}

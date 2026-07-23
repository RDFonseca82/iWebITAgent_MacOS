import Foundation

public enum SnapshotPrivacyViolation: Error, Equatable {
    case mobileDiskTelemetry
    case mobileUptimeTelemetry
    case mobileSerialNumber
    case mobileApplicationInventory
    case mobileServiceInventory
    case mobileSecurityPosture
    case locationWithoutAuthorization
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
}

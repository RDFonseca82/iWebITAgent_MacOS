import Foundation

public enum RemoteCapability: String, Codable, CaseIterable, Sendable {
    case packageUpdate
    case restart
    case shutdown
    case removeApplication
    case screenshot
    case location
}

public enum CapabilityDelivery: String, Codable, Sendable {
    case nativeAgent
    case appStore
    case userMediated
    case unavailable
}

public struct CapabilityContext: Codable, Equatable, Sendable {
    public let platform: ApplePlatform
    public let osVersion: String

    public init(platform: ApplePlatform, osVersion: String) {
        self.platform = platform
        self.osVersion = osVersion
    }
}

public struct CapabilityAvailability: Codable, Equatable, Sendable {
    public let capability: RemoteCapability
    public let isAvailable: Bool
    public let delivery: CapabilityDelivery
    public let requiresUserConsent: Bool
    public let reason: String

    public init(capability: RemoteCapability, isAvailable: Bool, delivery: CapabilityDelivery, requiresUserConsent: Bool, reason: String) {
        self.capability = capability
        self.isAvailable = isAvailable
        self.delivery = delivery
        self.requiresUserConsent = requiresUserConsent
        self.reason = reason
    }
}

public enum AppleCapabilityMatrix {
    public static func all(for context: CapabilityContext) -> [CapabilityAvailability] {
        RemoteCapability.allCases.map { availability(of: $0, for: context) }
    }

    public static func availability(of capability: RemoteCapability, for context: CapabilityContext) -> CapabilityAvailability {
        let minimumMajorVersion = context.platform == .macOS ? 11 : 15
        guard majorVersion(context.osVersion) >= minimumMajorVersion else {
            return unavailable(capability, "This build supports macOS 11+ and iOS/iPadOS 15+.")
        }

        switch context.platform {
        case .macOS: return macOS(capability)
        case .iOS, .iPadOS: return mobile(capability)
        }
    }

    private static func majorVersion(_ value: String) -> Int {
        Int(value.split(separator: ".").first ?? "0") ?? 0
    }

    private static func macOS(_ capability: RemoteCapability) -> CapabilityAvailability {
        switch capability {
        case .packageUpdate:
            return available(capability, .nativeAgent, false, "Signed, notarized .pkg verified by manifest, Apple signature and Gatekeeper.")
        case .restart, .shutdown:
            return available(capability, .nativeAgent, false, "Executed by the privileged daemon after signed-command authorization.")
        case .removeApplication:
            return available(capability, .nativeAgent, false, "Restricted to an allowlisted bundle in /Applications and audited.")
        case .screenshot:
            return available(capability, .userMediated, true, "Requires Screen Recording permission in the logged-in UI session.")
        case .location:
            return available(capability, .userMediated, true, "Requires Location Services authorization in the logged-in UI session.")
        }
    }

    private static func mobile(_ capability: RemoteCapability) -> CapabilityAvailability {
        switch capability {
        case .packageUpdate:
            return available(capability, .appStore, false, "Updates are delivered by the App Store or TestFlight; .pkg is macOS-only.")
        case .restart, .shutdown:
            return unavailable(capability, "An iOS/iPadOS application cannot restart or shut down the device.")
        case .removeApplication:
            return unavailable(capability, "An iOS/iPadOS application cannot remove other applications.")
        case .screenshot:
            return unavailable(capability, "An iOS/iPadOS application cannot capture arbitrary remote screenshots. User-created support attachments are a separate feature.")
        case .location:
            return available(capability, .userMediated, true, "A one-shot location is collected only after an explicit user action and system authorization.")
        }
    }

    private static func available(_ capability: RemoteCapability, _ delivery: CapabilityDelivery, _ requiresConsent: Bool, _ reason: String) -> CapabilityAvailability {
        CapabilityAvailability(capability: capability, isAvailable: true, delivery: delivery, requiresUserConsent: requiresConsent, reason: reason)
    }

    private static func unavailable(_ capability: RemoteCapability, _ reason: String) -> CapabilityAvailability {
        CapabilityAvailability(capability: capability, isAvailable: false, delivery: .unavailable, requiresUserConsent: false, reason: reason)
    }
}
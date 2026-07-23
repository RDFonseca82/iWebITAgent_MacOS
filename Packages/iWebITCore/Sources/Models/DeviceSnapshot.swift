import Foundation

public enum ApplePlatform: String, Codable, CaseIterable, Sendable {
    case macOS
    case iOS
    case iPadOS
}

public enum DataSource: String, Codable, Sendable {
    case application
    case privilegedAgent
    case user
}

public enum CollectionState: String, Codable, Sendable {
    case collected
    case unavailable
    case permissionDenied
    case unsupported
    case notManaged
    case failed
}

public struct CollectionResult: Codable, Equatable, Sendable {
    public let category: String
    public let state: CollectionState
    public let source: DataSource
    public let message: String?

    public init(category: String, state: CollectionState, source: DataSource, message: String? = nil) {
        self.category = category
        self.state = state
        self.source = source
        self.message = message
    }
}

public struct DeviceSnapshot: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = "2.0"

    public let schemaVersion: String
    public let snapshotID: UUID
    public let collectedAt: Date
    public let platform: ApplePlatform
    public let identity: DeviceIdentity
    public let operatingSystem: OperatingSystemInfo
    public let hardware: HardwareInfo
    public let storage: StorageInfo
    public let battery: BatteryInfo?
    public let network: NetworkInfo
    public let security: SecurityInfo
    public let management: ManagementInfo
    public let agent: AgentInfo
    public let location: LocationInfo?
    public let applications: [InstalledApplication]
    public let services: [SystemService]
    public let permissions: [PermissionInfo]
    public let collection: [CollectionResult]

    public init(
        schemaVersion: String = DeviceSnapshot.currentSchemaVersion,
        snapshotID: UUID = UUID(),
        collectedAt: Date = Date(),
        platform: ApplePlatform,
        identity: DeviceIdentity,
        operatingSystem: OperatingSystemInfo,
        hardware: HardwareInfo,
        storage: StorageInfo,
        battery: BatteryInfo?,
        network: NetworkInfo,
        security: SecurityInfo,
        management: ManagementInfo,
        agent: AgentInfo,
        location: LocationInfo?,
        applications: [InstalledApplication] = [],
        services: [SystemService] = [],
        permissions: [PermissionInfo] = [],
        collection: [CollectionResult] = []
    ) {
        self.schemaVersion = schemaVersion
        self.snapshotID = snapshotID
        self.collectedAt = collectedAt
        self.platform = platform
        self.identity = identity
        self.operatingSystem = operatingSystem
        self.hardware = hardware
        self.storage = storage
        self.battery = battery
        self.network = network
        self.security = security
        self.management = management
        self.agent = agent
        self.location = location
        self.applications = applications
        self.services = services
        self.permissions = permissions
        self.collection = collection
    }
}

public struct DeviceIdentity: Codable, Equatable, Sendable {
    public let deviceID: String
    public let displayName: String?
    public let serialNumber: String?
    public let model: String
    public let modelIdentifier: String?
    public let vendorIdentifier: UUID?
    public let ownership: String?

    public init(
        deviceID: String,
        displayName: String? = nil,
        serialNumber: String? = nil,
        model: String,
        modelIdentifier: String? = nil,
        vendorIdentifier: UUID? = nil,
        ownership: String? = nil
    ) {
        self.deviceID = deviceID
        self.displayName = displayName
        self.serialNumber = serialNumber
        self.model = model
        self.modelIdentifier = modelIdentifier
        self.vendorIdentifier = vendorIdentifier
        self.ownership = ownership
    }
}

public struct OperatingSystemInfo: Codable, Equatable, Sendable {
    public let name: String
    public let version: String
    public let build: String?
    public let kernelVersion: String?
    public let locale: String
    public let timeZone: String
    public let uptimeSeconds: TimeInterval?

    public init(
        name: String,
        version: String,
        build: String? = nil,
        kernelVersion: String? = nil,
        locale: String,
        timeZone: String,
        uptimeSeconds: TimeInterval? = nil
    ) {
        self.name = name
        self.version = version
        self.build = build
        self.kernelVersion = kernelVersion
        self.locale = locale
        self.timeZone = timeZone
        self.uptimeSeconds = uptimeSeconds
    }
}

public struct HardwareInfo: Codable, Equatable, Sendable {
    public let architecture: String
    public let processor: String?
    public let processorCount: Int
    public let activeProcessorCount: Int
    public let physicalMemoryBytes: UInt64
    public let bootROMVersion: String?
    public let smcVersion: String?

    public init(
        architecture: String,
        processor: String? = nil,
        processorCount: Int,
        activeProcessorCount: Int,
        physicalMemoryBytes: UInt64,
        bootROMVersion: String? = nil,
        smcVersion: String? = nil
    ) {
        self.architecture = architecture
        self.processor = processor
        self.processorCount = processorCount
        self.activeProcessorCount = activeProcessorCount
        self.physicalMemoryBytes = physicalMemoryBytes
        self.bootROMVersion = bootROMVersion
        self.smcVersion = smcVersion
    }
}

public struct StorageInfo: Codable, Equatable, Sendable {
    public let totalBytes: Int64?
    public let availableBytes: Int64?
    public let importantUsageAvailableBytes: Int64?
    public let opportunisticUsageAvailableBytes: Int64?

    public init(
        totalBytes: Int64? = nil,
        availableBytes: Int64? = nil,
        importantUsageAvailableBytes: Int64? = nil,
        opportunisticUsageAvailableBytes: Int64? = nil
    ) {
        self.totalBytes = totalBytes
        self.availableBytes = availableBytes
        self.importantUsageAvailableBytes = importantUsageAvailableBytes
        self.opportunisticUsageAvailableBytes = opportunisticUsageAvailableBytes
    }
}

public struct BatteryInfo: Codable, Equatable, Sendable {
    public let level: Double?
    public let state: String?
    public let isLowPowerModeEnabled: Bool
    public let cycleCount: Int?
    public let health: String?
    public let temperatureCelsius: Double?

    public init(
        level: Double? = nil,
        state: String? = nil,
        isLowPowerModeEnabled: Bool,
        cycleCount: Int? = nil,
        health: String? = nil,
        temperatureCelsius: Double? = nil
    ) {
        self.level = level
        self.state = state
        self.isLowPowerModeEnabled = isLowPowerModeEnabled
        self.cycleCount = cycleCount
        self.health = health
        self.temperatureCelsius = temperatureCelsius
    }
}

public struct NetworkInterfaceInfo: Codable, Equatable, Sendable {
    public let name: String
    public let type: String?
    public let addresses: [String]
    public let macAddress: String?
    public let isActive: Bool

    public init(name: String, type: String? = nil, addresses: [String], macAddress: String? = nil, isActive: Bool) {
        self.name = name
        self.type = type
        self.addresses = addresses
        self.macAddress = macAddress
        self.isActive = isActive
    }
}

public struct NetworkInfo: Codable, Equatable, Sendable {
    public let hostName: String?
    public let interfaces: [NetworkInterfaceInfo]
    public let currentTransport: String?
    public let isExpensive: Bool?
    public let isConstrained: Bool?

    public init(
        hostName: String? = nil,
        interfaces: [NetworkInterfaceInfo] = [],
        currentTransport: String? = nil,
        isExpensive: Bool? = nil,
        isConstrained: Bool? = nil
    ) {
        self.hostName = hostName
        self.interfaces = interfaces
        self.currentTransport = currentTransport
        self.isExpensive = isExpensive
        self.isConstrained = isConstrained
    }
}

public struct SecurityInfo: Codable, Equatable, Sendable {
    public let isPasscodePresent: Bool?
    public let isEncrypted: Bool?
    public let secureBootLevel: String?
    public let systemIntegrityProtectionEnabled: Bool?
    public let firewallEnabled: Bool?
    public let gatekeeperEnabled: Bool?
    public let activationLockEnabled: Bool?
    public let compromised: Bool?

    public init(
        isPasscodePresent: Bool? = nil,
        isEncrypted: Bool? = nil,
        secureBootLevel: String? = nil,
        systemIntegrityProtectionEnabled: Bool? = nil,
        firewallEnabled: Bool? = nil,
        gatekeeperEnabled: Bool? = nil,
        activationLockEnabled: Bool? = nil,
        compromised: Bool? = nil
    ) {
        self.isPasscodePresent = isPasscodePresent
        self.isEncrypted = isEncrypted
        self.secureBootLevel = secureBootLevel
        self.systemIntegrityProtectionEnabled = systemIntegrityProtectionEnabled
        self.firewallEnabled = firewallEnabled
        self.gatekeeperEnabled = gatekeeperEnabled
        self.activationLockEnabled = activationLockEnabled
        self.compromised = compromised
    }
}

public struct ManagementInfo: Codable, Equatable, Sendable {
    public let isManaged: Bool
    public let isSupervised: Bool?
    public let enrollmentType: String?
    public let serverURL: String?
    public let organization: String?
    public let declarativeManagementEnabled: Bool?

    public init(
        isManaged: Bool,
        isSupervised: Bool? = nil,
        enrollmentType: String? = nil,
        serverURL: String? = nil,
        organization: String? = nil,
        declarativeManagementEnabled: Bool? = nil
    ) {
        self.isManaged = isManaged
        self.isSupervised = isSupervised
        self.enrollmentType = enrollmentType
        self.serverURL = serverURL
        self.organization = organization
        self.declarativeManagementEnabled = declarativeManagementEnabled
    }
}

public struct AgentInfo: Codable, Equatable, Sendable {
    public let version: String
    public let build: String
    public let bundleIdentifier: String
    public let lastSuccessfulSyncAt: Date?
    public let pushTokenAvailable: Bool
    public let backgroundRefreshStatus: String?

    public init(
        version: String,
        build: String,
        bundleIdentifier: String,
        lastSuccessfulSyncAt: Date? = nil,
        pushTokenAvailable: Bool,
        backgroundRefreshStatus: String? = nil
    ) {
        self.version = version
        self.build = build
        self.bundleIdentifier = bundleIdentifier
        self.lastSuccessfulSyncAt = lastSuccessfulSyncAt
        self.pushTokenAvailable = pushTokenAvailable
        self.backgroundRefreshStatus = backgroundRefreshStatus
    }
}

public struct LocationInfo: Codable, Equatable, Sendable {
    public let latitude: Double
    public let longitude: Double
    public let horizontalAccuracyMeters: Double
    public let altitudeMeters: Double?
    public let recordedAt: Date
    public let authorization: String

    public init(
        latitude: Double,
        longitude: Double,
        horizontalAccuracyMeters: Double,
        altitudeMeters: Double? = nil,
        recordedAt: Date,
        authorization: String
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.horizontalAccuracyMeters = horizontalAccuracyMeters
        self.altitudeMeters = altitudeMeters
        self.recordedAt = recordedAt
        self.authorization = authorization
    }
}

public struct InstalledApplication: Codable, Equatable, Sendable {
    public let name: String
    public let bundleIdentifier: String?
    public let version: String?
    public let build: String?
    public let installedAt: Date?
    public let path: String?
    public let managed: Bool?
    public let source: DataSource

    public init(
        name: String,
        bundleIdentifier: String? = nil,
        version: String? = nil,
        build: String? = nil,
        installedAt: Date? = nil,
        path: String? = nil,
        managed: Bool? = nil,
        source: DataSource
    ) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.version = version
        self.build = build
        self.installedAt = installedAt
        self.path = path
        self.managed = managed
        self.source = source
    }
}

public struct SystemService: Codable, Equatable, Sendable {
    public let label: String
    public let state: String
    public let startMode: String?
    public let executablePath: String?
    public let processIdentifier: Int?

    public init(
        label: String,
        state: String,
        startMode: String? = nil,
        executablePath: String? = nil,
        processIdentifier: Int? = nil
    ) {
        self.label = label
        self.state = state
        self.startMode = startMode
        self.executablePath = executablePath
        self.processIdentifier = processIdentifier
    }
}

public struct PermissionInfo: Codable, Equatable, Sendable {
    public let capability: String
    public let authorization: String
    public let required: Bool

    public init(capability: String, authorization: String, required: Bool) {
        self.capability = capability
        self.authorization = authorization
        self.required = required
    }
}

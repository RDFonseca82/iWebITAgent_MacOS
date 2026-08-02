import Foundation

public struct LegacyAppleCredentials: Codable, Equatable, Sendable {
    public let idSync: String
    public let uniqueID: String
    public let idCompany: String?

    public init(idSync: String, uniqueID: String, idCompany: String? = nil) {
        self.idSync = idSync
        self.uniqueID = uniqueID
        self.idCompany = idCompany
    }
}

public struct LegacyAppleAPIClient: Sendable {
    private let syncURL: URL
    private let apiURL: URL
    private let supportURL: URL
    private let transport: any HTTPTransport

    public init(
        syncURL: URL,
        apiURL: URL,
        supportURL: URL,
        transport: any HTTPTransport = URLSessionTransport()
    ) throws {
        self.syncURL = try Self.requireHTTPS(syncURL)
        self.apiURL = try Self.requireHTTPS(apiURL)
        self.supportURL = try Self.requireHTTPS(supportURL)
        self.transport = transport
    }

    public func company(idSync: String) async throws -> LegacyCompanyResponse {
        guard var components = URLComponents(url: apiURL, resolvingAgainstBaseURL: false) else {
            throw CoreError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "IdSync", value: idSync)]
        guard let url = components.url else { throw CoreError.invalidURL }
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        let (data, response) = try await transport.data(for: request)
        try Self.validate(response)
        let value = String(decoding: data, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.lowercased() != "null" else {
            throw CoreError.unauthorized
        }
        let company = try JSONDecoder().decode(LegacyCompanyResponse.self, from: data)
        guard company.idSync != nil,
              let idCompany = company.idCompany,
              !idCompany.isEmpty,
              company.active != 0 else {
            throw CoreError.unauthorized
        }
        return company
    }
    public func synchronize(
        _ snapshot: DeviceSnapshot,
        credentials: LegacyAppleCredentials,
        pushToken: String? = nil
    ) async throws {
        let payload = LegacyAppleSyncPayload(
            snapshot: snapshot,
            credentials: credentials,
            pushToken: pushToken
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let json = String(decoding: try encoder.encode(payload), as: UTF8.self)
        var request = URLRequest(url: syncURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue(
            "application/x-www-form-urlencoded; charset=utf-8",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = Self.formData(["json": json])

        let (_, response) = try await transport.data(for: request)
        try Self.validate(response)
    }

    public func tickets(uniqueID: String) async throws -> [SupportTicket] {
        guard var components = URLComponents(url: apiURL, resolvingAgainstBaseURL: false) else {
            throw CoreError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "Support", value: "1"),
            URLQueryItem(name: "UniqueID", value: uniqueID)
        ]
        guard let url = components.url else { throw CoreError.invalidURL }
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        let (data, response) = try await transport.data(for: request)
        try Self.validate(response)
        let normalized = try LegacyResponseNormalizer.supportArrayData(from: data)
        let messages = try JSONDecoder().decode([LegacySupportResponse].self, from: normalized)
        return messages.enumerated().map { index, message in
            let date = Self.supportDate(message.date) ?? Date(timeIntervalSince1970: 0)
            return SupportTicket(
                id: "\(message.date ?? "unknown")-\(index)",
                subject: message.name ?? "Suporte",
                latestMessage: message.message ?? "",
                createdAt: date,
                updatedAt: date,
                status: .open
            )
        }
    }

    public func createTicket(
        uniqueID: String,
        name: String,
        message: String
    ) async throws -> SupportTicket {
        guard var components = URLComponents(url: supportURL, resolvingAgainstBaseURL: false) else {
            throw CoreError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "UniqueID", value: uniqueID)]
        guard let url = components.url else { throw CoreError.invalidURL }
        let now = Date()
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue(
            "application/x-www-form-urlencoded; charset=utf-8",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = Self.formData([
            "Nome": name,
            "DeviceSupport": message,
            "DeviceSupportDate": Self.legacyDate(now)
        ])
        let (_, response) = try await transport.data(for: request)
        try Self.validate(response)
        return SupportTicket(
            id: UUID().uuidString,
            subject: name,
            latestMessage: message,
            createdAt: now,
            updatedAt: now,
            status: .open
        )
    }

    private static func validate(_ response: HTTPURLResponse) throws {
        guard (200..<300).contains(response.statusCode) else {
            if response.statusCode == 401 || response.statusCode == 403 {
                throw CoreError.unauthorized
            }
            throw CoreError.server(statusCode: response.statusCode)
        }
    }

    private static func requireHTTPS(_ url: URL) throws -> URL {
        guard url.scheme?.lowercased() == "https" else { throw CoreError.insecureTransport }
        return url
    }

    private static func formData(_ fields: [String: String]) -> Data {
        var components = URLComponents()
        components.queryItems = fields.sorted { $0.key < $1.key }.map {
            URLQueryItem(name: $0.key, value: $0.value)
        }
        return Data((components.percentEncodedQuery ?? "").utf8)
    }

    private static func legacyDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }

    private static func supportDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: value)
    }
}

private struct LegacyApplicationPayload: Encodable, Sendable {
    let name: String
    let date: String

    init(_ application: InstalledApplication) {
        name = application.name
        if let installedAt = application.installedAt {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            date = formatter.string(from: installedAt)
        } else {
            date = "1900-01-01 00:00:01"
        }
    }
}

private struct LegacyServicePayload: Encodable, Sendable {
    let name: String
    let state: String
    let startMode: String?
    let pathName: String?

    init(_ service: SystemService) {
        name = service.label
        state = service.state
        startMode = service.startMode
        pathName = service.executablePath
    }

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case state = "State"
        case startMode = "StartMode"
        case pathName = "PathName"
    }
}
private struct LegacyAppleSyncPayload: Encodable, Sendable {
    let typeSync = "1"
    let uniqueID: String
    let idSync: String
    let idCompany: String?
    let lastConnectDate: String
    let agentVersion: String
    let appBuild: String
    let idDeviceType = 62
    let appleType: Int
    let computerSystemUserName: String?
    let computerSystemDNSHostName: String?
    let deviceHost: String?
    let appleMemoryTotal: UInt64
    let appleMemoryUsed: Int64?
    let appleVersion: String
    let appleOSBuild: String?
    let appleKernelVersion: String?
    let appleLocale: String
    let appleTimeZone: String
    let appleModel: String
    let appleArchitecture: String
    let appleCpuType: String
    let appleNProcessors: Int
    let appleActiveProcessors: Int
    let appleBootRomVersion: String?
    let appleSerialNumber: String?
    let appleSMCVersionSystem: String?
    let appleStorage: Int64?
    let appleStorageUsed: Int64?
    let appleBattery: Double?
    let appleBatteryState: String?
    let appleBatteryCycleCount: Int?
    let appleBatteryHealth: String?
    let appleBatteryTemperature: Double?
    let lowPowerMode: Bool?
    let networkTransport: String?
    let networkExpensive: Bool?
    let networkConstrained: Bool?
    let pushToken: String?
    let agentBundleIdentifier: String
    let backgroundRefreshStatus: String?
    let applications: [LegacyApplicationPayload]
    let services: [LegacyServicePayload]
    let permissions: [PermissionInfo]
    let collection: [CollectionResult]
    let latitude: Double?
    let longitude: Double?
    let locationAccuracy: Double?
    let snapshotSchemaVersion: String
    let snapshotID: String

    init(
        snapshot: DeviceSnapshot,
        credentials: LegacyAppleCredentials,
        pushToken: String?
    ) {
        uniqueID = credentials.uniqueID
        idSync = credentials.idSync
        idCompany = credentials.idCompany
        lastConnectDate = Self.legacyDate(snapshot.collectedAt)
        agentVersion = snapshot.agent.version
        appBuild = snapshot.agent.build
        appleType = snapshot.platform == .macOS ? 1 : 2
        computerSystemUserName = snapshot.identity.displayName
        computerSystemDNSHostName = snapshot.network.hostName
        deviceHost = snapshot.network.interfaces.lazy.flatMap { $0.addresses }.first
            ?? snapshot.network.hostName
        appleMemoryTotal = snapshot.hardware.physicalMemoryBytes
        appleMemoryUsed = nil
        appleVersion = snapshot.operatingSystem.version
        appleOSBuild = snapshot.operatingSystem.build
        appleKernelVersion = snapshot.operatingSystem.kernelVersion
        appleLocale = snapshot.operatingSystem.locale
        appleTimeZone = snapshot.operatingSystem.timeZone
        appleModel = snapshot.identity.modelIdentifier ?? snapshot.identity.model
        appleArchitecture = snapshot.hardware.architecture
        appleCpuType = snapshot.hardware.processor ?? snapshot.hardware.architecture
        appleNProcessors = snapshot.hardware.processorCount
        appleActiveProcessors = snapshot.hardware.activeProcessorCount
        appleBootRomVersion = snapshot.hardware.bootROMVersion
        appleSerialNumber = snapshot.identity.serialNumber
        appleSMCVersionSystem = snapshot.hardware.smcVersion
        appleStorage = snapshot.storage.totalBytes
        if let total = snapshot.storage.totalBytes, let available = snapshot.storage.availableBytes {
            appleStorageUsed = max(0, total - available)
        } else {
            appleStorageUsed = nil
        }
        appleBattery = snapshot.battery?.level.map { $0 * 100 }
        appleBatteryState = snapshot.battery?.state
        appleBatteryCycleCount = snapshot.battery?.cycleCount
        appleBatteryHealth = snapshot.battery?.health
        appleBatteryTemperature = snapshot.battery?.temperatureCelsius
        lowPowerMode = snapshot.battery?.isLowPowerModeEnabled
        networkTransport = snapshot.network.currentTransport
        networkExpensive = snapshot.network.isExpensive
        networkConstrained = snapshot.network.isConstrained
        self.pushToken = pushToken
        agentBundleIdentifier = snapshot.agent.bundleIdentifier
        backgroundRefreshStatus = snapshot.agent.backgroundRefreshStatus
        applications = snapshot.applications.map(LegacyApplicationPayload.init)
        services = snapshot.services.map(LegacyServicePayload.init)
        permissions = snapshot.permissions
        collection = snapshot.collection
        latitude = snapshot.location?.latitude
        longitude = snapshot.location?.longitude
        locationAccuracy = snapshot.location?.horizontalAccuracyMeters
        snapshotSchemaVersion = snapshot.schemaVersion
        snapshotID = snapshot.snapshotID.uuidString.lowercased()
    }

    enum CodingKeys: String, CodingKey {
        case typeSync = "TypeSync"
        case uniqueID = "UniqueID"
        case idSync = "IDSync"
        case idCompany = "IdCompany"
        case lastConnectDate = "LastConnectDate"
        case agentVersion = "AgentVersion"
        case appBuild = "AppBuild"
        case idDeviceType = "IdDeviceType"
        case appleType = "AppleType"
        case computerSystemUserName = "ComputerSystem_UserName"
        case computerSystemDNSHostName = "ComputerSystem_DNSHostName"
        case deviceHost = "DeviceHost"
        case appleMemoryTotal = "AppleMemoryTotal"
        case appleMemoryUsed = "AppleMemoryUsed"
        case appleVersion = "AppleVersion"
        case appleOSBuild = "AppleOSBuild"
        case appleKernelVersion = "AppleKernelVersion"
        case appleLocale = "AppleLocale"
        case appleTimeZone = "AppleTimeZone"
        case appleModel = "AppleModel"
        case appleArchitecture = "AppleArchitecture"
        case appleCpuType = "AppleCpuType"
        case appleNProcessors = "AppleNProcessors"
        case appleActiveProcessors = "AppleActiveProcessors"
        case appleBootRomVersion = "AppleBootRomVersion"
        case appleSerialNumber = "AppleSerialNumber"
        case appleSMCVersionSystem = "AppleSMCVersionSystem"
        case appleStorage = "AppleStorage"
        case appleStorageUsed = "AppleStorageUsed"
        case appleBattery = "AppleBattery"
        case appleBatteryState = "AppleBatteryState"
        case appleBatteryCycleCount = "AppleBatteryCycleCount"
        case appleBatteryHealth = "AppleBatteryHealth"
        case appleBatteryTemperature = "AppleBatteryTemperature"
        case lowPowerMode = "AppleLowPowerMode"
        case networkTransport = "AppleNetworkTransport"
        case networkExpensive = "AppleNetworkExpensive"
        case networkConstrained = "AppleNetworkConstrained"
        case pushToken = "ApplePushToken"
        case agentBundleIdentifier = "AppleAgentBundleIdentifier"
        case backgroundRefreshStatus = "AppleBackgroundRefreshStatus"
        case applications = "Aplications"
        case services = "Services"
        case permissions = "ApplePermissions"
        case collection = "AppleCollection"
        case latitude = "Latitude"
        case longitude = "Longitude"
        case locationAccuracy = "LocationAccuracy"
        case snapshotSchemaVersion = "SnapshotSchemaVersion"
        case snapshotID = "SnapshotID"
    }

    private static func legacyDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

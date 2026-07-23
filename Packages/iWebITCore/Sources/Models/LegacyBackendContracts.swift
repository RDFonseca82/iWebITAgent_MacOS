import Foundation

public struct LegacyCompanyResponse: Codable, Equatable, Sendable {
    public let idSync: String?
    public let idCompany: String?
    public let company: String?
    public let active: Int?
    public let logoOnline: String?
    public let logoOffline: String?
    public let logoInactive: String?
    public let eventViewerLines: Int?
    public let timeSync: Int?
    public let timeAlive: Int?
    public let appleAgentVersion: String?
    public let appleAgentDownload: String?

    enum CodingKeys: String, CodingKey {
        case idSync = "IDSync"
        case idCompany = "IdCompany"
        case company = "Company"
        case active = "Active"
        case logoOnline = "LogoOnline"
        case logoOffline = "LogoOffline"
        case logoInactive = "LogoInactive"
        case eventViewerLines = "EventViewerLines"
        case timeSync = "TimeSync"
        case timeAlive = "TimeAlive"
        case appleAgentVersion = "AppleAgentVersion"
        case appleAgentDownload = "AppleAgentDownload"
    }
}

public struct LegacyDeviceResponse: Codable, Equatable, Sendable {
    public let idDevice: String?
    public let uniqueID: String?
    public let idCompany: String?
    public let idSync: String?
    public let idDeviceType: Int?
    public let active: Int?
    public let fullSync: Int?
    public let deviceLocation: Int?
    public let operatingSystemReboot: Int?
    public let operatingSystemShutDown: Int?
    public let timeSync: Int?
    public let timeAlive: Int?
    public let messageText: String?
    public let printScreen: Int?

    enum CodingKeys: String, CodingKey {
        case idDevice = "IdDevice"
        case uniqueID = "UniqueID"
        case idCompany = "IdCompany"
        case idSync = "IDSync"
        case idDeviceType = "IdDeviceType"
        case active = "Active"
        case fullSync = "FullSync"
        case deviceLocation = "DeviceLocation"
        case operatingSystemReboot = "OperatingSystem_Reboot"
        case operatingSystemShutDown = "OperatingSystem_ShutDown"
        case timeSync = "TimeSync"
        case timeAlive = "TimeAlive"
        case messageText = "AndroidMessageTxt"
        case printScreen = "WindowsPrintScreen"
    }
}

public struct LegacySupportResponse: Codable, Equatable, Sendable {
    public let name: String?
    public let message: String?
    public let date: String?

    enum CodingKeys: String, CodingKey {
        case name = "Nome"
        case message = "DeviceSupport"
        case date = "DeviceSupportDate"
    }
}

public enum LegacyResponseNormalizer {
    /// The legacy support endpoint may return adjacent JSON objects instead of an array.
    public static func supportArrayData(from data: Data) throws -> Data {
        guard var value = String(data: data, encoding: .utf8) else {
            throw CoreError.invalidResponse
        }
        value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if value == "null" || value.isEmpty {
            return Data("[]".utf8)
        }
        if value.hasPrefix("[") {
            return Data(value.utf8)
        }
        value = "[\(value.replacingOccurrences(of: "}{", with: "},{"))]"
        return Data(value.utf8)
    }
}

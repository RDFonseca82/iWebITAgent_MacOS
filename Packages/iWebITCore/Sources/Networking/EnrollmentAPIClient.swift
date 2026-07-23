import Foundation

public struct DeviceEnrollmentRequest: Codable, Equatable, Sendable {
    public let idSync: String
    public let platform: ApplePlatform
    public let appVersion: String
    public let appBuild: String
    public let vendorIdentifier: UUID?
    public let attestation: Data?

    public init(
        idSync: String,
        platform: ApplePlatform,
        appVersion: String,
        appBuild: String,
        vendorIdentifier: UUID? = nil,
        attestation: Data? = nil
    ) {
        self.idSync = idSync
        self.platform = platform
        self.appVersion = appVersion
        self.appBuild = appBuild
        self.vendorIdentifier = vendorIdentifier
        self.attestation = attestation
    }
}

public struct DeviceEnrollmentResponse: Codable, Equatable, Sendable {
    public let deviceID: String
    public let keyID: String
    public let sharedSecret: Data
    public let commandPublicKeys: [String: Data]
    public let updatePublicKeys: [String: Data]

    public init(
        deviceID: String,
        keyID: String,
        sharedSecret: Data,
        commandPublicKeys: [String: Data],
        updatePublicKeys: [String: Data]
    ) {
        self.deviceID = deviceID
        self.keyID = keyID
        self.sharedSecret = sharedSecret
        self.commandPublicKeys = commandPublicKeys
        self.updatePublicKeys = updatePublicKeys
    }
}

public struct EnrollmentAPIClient: Sendable {
    private let environment: APIEnvironment
    private let transport: any HTTPTransport

    public init(
        environment: APIEnvironment,
        transport: any HTTPTransport = URLSessionTransport()
    ) {
        self.environment = environment
        self.transport = transport
    }

    public func enroll(_ enrollment: DeviceEnrollmentRequest) async throws -> DeviceEnrollmentResponse {
        let url = environment.baseURL.appendingPathComponent("v2/enrollments")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        request.httpBody = try encoder.encode(enrollment)

        let (data, response) = try await transport.data(for: request)
        guard (200..<300).contains(response.statusCode) else {
            if response.statusCode == 401 || response.statusCode == 403 {
                throw CoreError.unauthorized
            }
            throw CoreError.server(statusCode: response.statusCode)
        }
        let result = try JSONDecoder().decode(DeviceEnrollmentResponse.self, from: data)
        guard result.sharedSecret.count >= 32,
              !result.deviceID.isEmpty,
              !result.keyID.isEmpty else {
            throw CoreError.invalidResponse
        }
        return result
    }
}

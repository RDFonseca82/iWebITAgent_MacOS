import Foundation

public enum RemoteCommandType: String, Codable, CaseIterable, Sendable {
    case installPackage = "install_package"
    case restart
    case shutdown
    case removeApplication = "remove_application"
    case captureScreen = "capture_screen"
    case requestLocation = "request_location"
}

public struct RestartCommandPayload: Codable, Equatable, Sendable {
    public let delaySeconds: Int
    public let reason: String
    public init(delaySeconds: Int = 60, reason: String) { self.delaySeconds = delaySeconds; self.reason = reason }
}

public struct ShutdownCommandPayload: Codable, Equatable, Sendable {
    public let delaySeconds: Int
    public let reason: String
    public init(delaySeconds: Int = 60, reason: String) { self.delaySeconds = delaySeconds; self.reason = reason }
}

public struct RemoveApplicationCommandPayload: Codable, Equatable, Sendable {
    public let bundleIdentifier: String
    public init(bundleIdentifier: String) { self.bundleIdentifier = bundleIdentifier }
}

public struct InstallPackageCommandPayload: Codable, Equatable, Sendable {
    public let manifest: SignedUpdateManifest
    public init(manifest: SignedUpdateManifest) { self.manifest = manifest }
}

public struct CaptureScreenCommandPayload: Codable, Equatable, Sendable {
    public let reason: String
    public init(reason: String) { self.reason = reason }
}

public struct RequestLocationCommandPayload: Codable, Equatable, Sendable {
    public let reason: String
    public let desiredAccuracyMeters: Double
    public init(reason: String, desiredAccuracyMeters: Double = 100) { self.reason = reason; self.desiredAccuracyMeters = desiredAccuracyMeters }
}

public struct RemoteCommandResult: Codable, Equatable, Sendable {
    public enum Status: String, Codable, Sendable { case acknowledged, completed, failed, requiresUserAction }
    public let commandID: UUID
    public let status: Status
    public let message: String?
    public let completedAt: Date
    public init(commandID: UUID, status: Status, message: String? = nil, completedAt: Date = Date()) {
        self.commandID = commandID; self.status = status; self.message = message; self.completedAt = completedAt
    }
}

public protocol RemoteCommandHandling: Sendable {
    func handle(_ command: SignedCommand, type: RemoteCommandType) async throws -> RemoteCommandResult
}

public actor SignedCommandProcessor {
    private let deviceID: String
    private let verifier: CommandVerifier
    private let replayGuard: CommandReplayGuard
    private let handler: any RemoteCommandHandling

    public init(deviceID: String, verifier: CommandVerifier, replayGuard: CommandReplayGuard = CommandReplayGuard(), handler: any RemoteCommandHandling) {
        self.deviceID = deviceID; self.verifier = verifier; self.replayGuard = replayGuard; self.handler = handler
    }

    public func process(_ command: SignedCommand, at date: Date = Date()) async throws -> RemoteCommandResult {
        try verifier.verify(command, for: deviceID, at: date)
        guard let type = RemoteCommandType(rawValue: command.type) else { throw CoreError.unsupportedCommand }
        try await replayGuard.accept(command, at: date)
        return try await handler.handle(command, type: type)
    }
}
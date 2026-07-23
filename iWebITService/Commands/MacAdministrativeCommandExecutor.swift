import Foundation
import iWebITCore

struct MacAdministrativeCommandExecutor: RemoteCommandHandling {
    typealias AuditSink = @Sendable (_ commandID: UUID, _ event: String) -> Void

    let packageInstaller: MacPackageUpdateInstaller
    let applicationRemover: MacApplicationRemover
    let audit: AuditSink

    func handle(
        _ command: SignedCommand,
        type: RemoteCommandType
    ) async throws -> RemoteCommandResult {
        audit(command.commandID, "authorized:\(type.rawValue)")

        do {
            switch type {
        case .restart:
            let payload = try decode(RestartCommandPayload.self, from: command.payload)
            try executeShutdown(flag: "-r", delaySeconds: payload.delaySeconds)
            return completed(command, "Restart scheduled.")

        case .shutdown:
            let payload = try decode(ShutdownCommandPayload.self, from: command.payload)
            try executeShutdown(flag: "-h", delaySeconds: payload.delaySeconds)
            return completed(command, "Shutdown scheduled.")

        case .removeApplication:
            let payload = try decode(RemoveApplicationCommandPayload.self, from: command.payload)
            try applicationRemover.remove(bundleIdentifier: payload.bundleIdentifier)
            return completed(command, "Managed application removed.")

        case .installPackage:
            let payload = try decode(InstallPackageCommandPayload.self, from: command.payload)
            try await packageInstaller.downloadVerifyAndInstall(manifest: payload.manifest)
            return completed(command, "Package installed.")

        case .captureScreen, .requestLocation:
            return RemoteCommandResult(
                commandID: command.commandID,
                status: .requiresUserAction,
                message: "Forward this authorized request to the signed user-session agent."
            )
            }
        } catch {
            audit(command.commandID, "failed:\(String(describing: error))")
            throw error
        }
    }

    private func executeShutdown(flag: String, delaySeconds: Int) throws {
        let boundedDelay = min(max(delaySeconds, 0), 3_600)
        let minutes = boundedDelay == 0 ? "now" : "+\(max(1, boundedDelay / 60))"
        let result = try ProcessRunner.run(
            executable: "/sbin/shutdown",
            arguments: [flag, minutes]
        )
        guard result.status == 0 else {
            throw MacAdministrativeCommandError.commandFailed(result.output)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw CoreError.invalidCommandPayload
        }
    }

    private func completed(
        _ command: SignedCommand,
        _ message: String
    ) -> RemoteCommandResult {
        audit(command.commandID, "completed")
        return RemoteCommandResult(
            commandID: command.commandID,
            status: .completed,
            message: message
        )
    }
}

struct MacApplicationRemover: Sendable {
    let allowedBundleIdentifiers: Set<String>
    let protectedBundleIdentifiers: Set<String>

    init(
        allowedBundleIdentifiers: Set<String>,
        protectedBundleIdentifiers: Set<String> = [
            "app.iwebit.agent",
            "app.iwebit.agent.menubar"
        ]
    ) {
        self.allowedBundleIdentifiers = allowedBundleIdentifiers
        self.protectedBundleIdentifiers = protectedBundleIdentifiers
    }

    func remove(bundleIdentifier: String) throws {
        guard allowedBundleIdentifiers.contains(bundleIdentifier),
              !protectedBundleIdentifiers.contains(bundleIdentifier) else {
            throw MacAdministrativeCommandError.applicationNotAllowed
        }

        let applications = URL(fileURLWithPath: "/Applications", isDirectory: true)
        let entries = try FileManager.default.contentsOfDirectory(
            at: applications,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        guard let application = entries.first(where: {
            $0.pathExtension.caseInsensitiveCompare("app") == .orderedSame &&
            Bundle(url: $0)?.bundleIdentifier == bundleIdentifier
        }) else {
            throw MacAdministrativeCommandError.applicationNotFound
        }

        let root = applications.standardizedFileURL.path + "/"
        let target = application.standardizedFileURL
        guard target.path.hasPrefix(root), target.pathExtension == "app" else {
            throw MacAdministrativeCommandError.invalidApplicationPath
        }

        try FileManager.default.removeItem(at: target)
    }
}

enum MacAdministrativeCommandError: Error {
    case commandFailed(String)
    case applicationNotAllowed
    case applicationNotFound
    case invalidApplicationPath
    case rollbackRejected
    case incompatibleOperatingSystem
}

enum ProcessRunner {
    static func run(
        executable: String,
        arguments: [String]
    ) throws -> (status: Int32, output: String) {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(decoding: data, as: UTF8.self))
    }
}

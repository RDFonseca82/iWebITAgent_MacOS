import Foundation
import iWebITCore

struct MacOSPackageVerifier: Sendable {
    let expectedTeamID: String
    let manifestVerifier: UpdateVerifier

    func verify(packageURL: URL, data: Data, manifest: SignedUpdateManifest) throws {
        try manifestVerifier.verifyArtifact(data, against: manifest)
        guard packageURL.isFileURL else {
            throw CoreError.updateManifestInvalid
        }

        let signature = try run(
            executable: URL(fileURLWithPath: "/usr/sbin/pkgutil"),
            arguments: ["--check-signature", packageURL.path]
        )
        guard signature.status == 0,
              signature.output.contains(expectedTeamID) else {
            throw MacOSUpdateVerificationError.untrustedPackageSigner
        }

        let assessment = try run(
            executable: URL(fileURLWithPath: "/usr/sbin/spctl"),
            arguments: ["--assess", "--type", "install", "--verbose=4", packageURL.path]
        )
        guard assessment.status == 0 else {
            throw MacOSUpdateVerificationError.gatekeeperRejected
        }
    }

    private func run(executable: URL, arguments: [String]) throws -> (status: Int32, output: String) {
        let process = Process()
        let output = Pipe()
        process.executableURL = executable
        process.arguments = arguments
        process.standardOutput = output
        process.standardError = output
        try process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(decoding: data, as: UTF8.self))
    }
}

enum MacOSUpdateVerificationError: Error {
    case untrustedPackageSigner
    case gatekeeperRejected
}

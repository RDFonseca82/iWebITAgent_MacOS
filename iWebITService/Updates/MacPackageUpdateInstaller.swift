import Foundation
import iWebITCore
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct MacPackageUpdateInstaller: Sendable {
    let verifier: MacOSPackageVerifier
    let installedBuild: Int
    let currentOSVersion: OperatingSystemVersion
    let session: URLSession

    init(
        verifier: MacOSPackageVerifier,
        installedBuild: Int,
        currentOSVersion: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion,
        session: URLSession = .shared
    ) {
        self.verifier = verifier
        self.installedBuild = installedBuild
        self.currentOSVersion = currentOSVersion
        self.session = session
    }

    func downloadVerifyAndInstall(manifest: SignedUpdateManifest) async throws {
        try verifier.manifestVerifier.verifyManifest(manifest)
        guard let candidateBuild = Int(manifest.build),
              candidateBuild > installedBuild else {
            throw MacAdministrativeCommandError.rollbackRejected
        }
        guard supports(minimumVersion: manifest.minimumOSVersion) else {
            throw MacAdministrativeCommandError.incompatibleOperatingSystem
        }
        guard manifest.downloadURL.scheme?.lowercased() == "https" else {
            throw CoreError.insecureTransport
        }

        let (temporaryURL, response) = try await download(from: manifest.downloadURL)
        defer { try? FileManager.default.removeItem(at: temporaryURL) }

        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw CoreError.invalidResponse
        }

        let data = try Data(contentsOf: temporaryURL, options: [.mappedIfSafe])
        try verifier.verify(
            packageURL: temporaryURL,
            data: data,
            manifest: manifest
        )

        let result = try ProcessRunner.run(
            executable: "/usr/sbin/installer",
            arguments: ["-pkg", temporaryURL.path, "-target", "/"]
        )
        guard result.status == 0 else {
            throw MacAdministrativeCommandError.commandFailed(result.output)
        }
    }

    private func download(from url: URL) async throws -> (URL, URLResponse) {
        if #available(macOS 12.0, *) {
            let (temporaryURL, response) = try await session.download(from: url)
            return (try persistDownload(at: temporaryURL), response)
        }

        return try await withCheckedThrowingContinuation { continuation in
            session.downloadTask(with: url) { url, response, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let url, let response {
                    do {
                        continuation.resume(returning: (try self.persistDownload(at: url), response))
                    } catch {
                        continuation.resume(throwing: error)
                    }
                } else {
                    continuation.resume(throwing: CoreError.invalidResponse)
                }
            }.resume()
        }
    }

    private func supports(minimumVersion value: String) -> Bool {
        let fields = value.split(separator: ".").compactMap { Int($0) }
        guard !fields.isEmpty else { return false }
        let minimum = [fields[0], fields.count > 1 ? fields[1] : 0, fields.count > 2 ? fields[2] : 0]
        let current = [currentOSVersion.majorVersion, currentOSVersion.minorVersion, currentOSVersion.patchVersion]
        return current.lexicographicallyPrecedes(minimum) == false
    }

    private func persistDownload(at temporaryURL: URL) throws -> URL {
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("pkg")
        try FileManager.default.moveItem(at: temporaryURL, to: destination)
        return destination
    }
}

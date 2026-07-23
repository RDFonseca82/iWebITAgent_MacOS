import Foundation
import iWebITCore
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct MacAutomaticUpdateConfiguration: Codable, Sendable {
    let schemaVersion: Int
    let manifestURL: URL
    let updatePublicKeys: [String: String]
    let expectedTeamID: String
    let checkIntervalSeconds: TimeInterval

    func validatedPublicKeys() throws -> [String: Data] {
        guard schemaVersion == 1,
              manifestURL.scheme?.lowercased() == "https",
              !expectedTeamID.isEmpty,
              checkIntervalSeconds >= 3_600 else {
            throw CoreError.updateManifestInvalid
        }

        let decoded = updatePublicKeys.compactMapValues { Data(base64Encoded: $0) }
        guard decoded.count == updatePublicKeys.count,
              !decoded.isEmpty,
              decoded.values.allSatisfy({ $0.count == 32 }) else {
            throw CoreError.updateManifestInvalid
        }
        return decoded
    }
}

actor MacAutomaticUpdateCoordinator {
    typealias AuditSink = @Sendable (String) -> Void

    static let defaultConfigurationURL = URL(
        fileURLWithPath: "/Library/Application Support/iWebITAgent/update-channel.json"
    )

    private let configuration: MacAutomaticUpdateConfiguration
    private let installer: MacPackageUpdateInstaller
    private let session: URLSession
    private let audit: AuditSink

    init(
        configuration: MacAutomaticUpdateConfiguration,
        installedBuild: Int,
        session: URLSession = .shared,
        audit: @escaping AuditSink
    ) throws {
        let keys = try configuration.validatedPublicKeys()
        let verifier = UpdateVerifier(publicKeys: keys)
        self.configuration = configuration
        self.installer = MacPackageUpdateInstaller(
            verifier: MacOSPackageVerifier(
                expectedTeamID: configuration.expectedTeamID,
                manifestVerifier: verifier
            ),
            installedBuild: installedBuild,
            session: session
        )
        self.session = session
        self.audit = audit
    }

    static func startIfConfigured(
        at url: URL = defaultConfigurationURL,
        installedBuild: Int,
        audit: @escaping AuditSink
    ) -> Task<Void, Never>? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            guard let owner = attributes[.ownerAccountID] as? NSNumber,
                  owner.intValue == 0,
                  let permissions = attributes[.posixPermissions] as? NSNumber,
                  permissions.intValue & 0o022 == 0 else {
                throw CoreError.updateManifestInvalid
            }
            let data = try Data(contentsOf: url)
            let configuration = try JSONDecoder().decode(
                MacAutomaticUpdateConfiguration.self,
                from: data
            )
            let coordinator = try MacAutomaticUpdateCoordinator(
                configuration: configuration,
                installedBuild: installedBuild,
                audit: audit
            )
            return Task.detached(priority: .utility) {
                await coordinator.run()
            }
        } catch {
            audit("automatic-update-disabled:\(String(describing: error))")
            return nil
        }
    }

    func run() async {
        while !Task.isCancelled {
            do {
                if try await checkOnce() {
                    audit("automatic-update-installed")
                }
            } catch MacAdministrativeCommandError.rollbackRejected {
                audit("automatic-update-current")
            } catch {
                audit("automatic-update-failed:\(String(describing: error))")
            }

            let seconds = min(max(configuration.checkIntervalSeconds, 3_600), 86_400)
            do {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            } catch {
                return
            }
        }
    }

    func checkOnce() async throws -> Bool {
        let manifest = try await fetchManifest()
        try await installer.downloadVerifyAndInstall(manifest: manifest)
        return true
    }

    private func fetchManifest() async throws -> SignedUpdateManifest {
        let (data, response) = try await data(from: configuration.manifestURL)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode),
              data.count <= 1_048_576 else {
            throw CoreError.invalidResponse
        }
        return try JSONDecoder().decode(SignedUpdateManifest.self, from: data)
    }

    private func data(from url: URL) async throws -> (Data, URLResponse) {
        if #available(macOS 12.0, *) {
            return try await session.data(from: url)
        }
        return try await withCheckedThrowingContinuation { continuation in
            session.dataTask(with: url) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data, let response {
                    continuation.resume(returning: (data, response))
                } else {
                    continuation.resume(throwing: CoreError.invalidResponse)
                }
            }.resume()
        }
    }
}

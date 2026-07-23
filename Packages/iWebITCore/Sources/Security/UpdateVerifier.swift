import CryptoKit
import Foundation

public struct SignedUpdateManifest: Codable, Equatable, Sendable {
    public let version: String
    public let build: String
    public let downloadURL: URL
    public let byteCount: Int64
    public let sha256: String
    public let minimumOSVersion: String
    public let keyID: String
    public let signature: Data

    public init(
        version: String,
        build: String,
        downloadURL: URL,
        byteCount: Int64,
        sha256: String,
        minimumOSVersion: String,
        keyID: String,
        signature: Data
    ) {
        self.version = version
        self.build = build
        self.downloadURL = downloadURL
        self.byteCount = byteCount
        self.sha256 = sha256
        self.minimumOSVersion = minimumOSVersion
        self.keyID = keyID
        self.signature = signature
    }

    public var signingData: Data {
        Data([
            version,
            build,
            downloadURL.absoluteString,
            String(byteCount),
            sha256.lowercased(),
            minimumOSVersion,
            keyID
        ].joined(separator: "\n").utf8)
    }
}

public struct UpdateVerifier: Sendable {
    private let publicKeys: [String: Data]

    public init(publicKeys: [String: Data]) {
        self.publicKeys = publicKeys
    }

    public func verifyManifest(_ manifest: SignedUpdateManifest) throws {
        guard manifest.downloadURL.scheme?.lowercased() == "https",
              manifest.byteCount >= 0,
              manifest.sha256.count == 64,
              let keyData = publicKeys[manifest.keyID],
              let publicKey = try? Curve25519.Signing.PublicKey(rawRepresentation: keyData),
              publicKey.isValidSignature(manifest.signature, for: manifest.signingData) else {
            throw CoreError.updateManifestInvalid
        }
    }

    public func verifyArtifact(_ data: Data, against manifest: SignedUpdateManifest) throws {
        try verifyManifest(manifest)
        guard Int64(data.count) == manifest.byteCount,
              RequestAuthenticator.sha256Hex(data) == manifest.sha256.lowercased() else {
            throw CoreError.checksumMismatch
        }
    }
}

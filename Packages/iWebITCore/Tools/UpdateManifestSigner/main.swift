import CryptoKit
import Foundation
import iWebITCore

struct Arguments {
    let artifact: URL
    let version: String
    let build: String
    let minimumOS: String
    let downloadURL: URL
    let keyID: String
    let privateKey: Data
    let publicKey: Data
    let output: URL

    init() throws {
        let values = CommandLine.arguments.dropFirst()
        var options: [String: String] = [:]
        var index = values.startIndex
        while index < values.endIndex {
            let key = values[index]
            let next = values.index(after: index)
            guard key.hasPrefix("--"), next < values.endIndex else {
                throw SignerError.usage
            }
            options[String(key.dropFirst(2))] = values[next]
            index = values.index(after: next)
        }

        guard let artifact = options["artifact"],
              let version = options["version"],
              let build = options["build"],
              let minimumOS = options["minimum-os"],
              let download = options["download-url"],
              let downloadURL = URL(string: download),
              downloadURL.scheme?.lowercased() == "https",
              let keyID = options["key-id"],
              let key = options["private-key-base64"],
              let privateKey = Data(base64Encoded: key),
              let publicKeyValue = options["public-key-base64"],
              let publicKey = Data(base64Encoded: publicKeyValue),
              let output = options["output"] else {
            throw SignerError.usage
        }

        self.artifact = URL(fileURLWithPath: artifact)
        self.version = version
        self.build = build
        self.minimumOS = minimumOS
        self.downloadURL = downloadURL
        self.keyID = keyID
        self.privateKey = privateKey
        self.publicKey = publicKey
        self.output = URL(fileURLWithPath: output)
    }
}

enum SignerError: Error {
    case usage
    case keyMismatch
}

do {
    let arguments = try Arguments()
    let artifact = try Data(contentsOf: arguments.artifact, options: [.mappedIfSafe])
    let unsigned = SignedUpdateManifest(
        version: arguments.version,
        build: arguments.build,
        downloadURL: arguments.downloadURL,
        byteCount: Int64(artifact.count),
        sha256: RequestAuthenticator.sha256Hex(artifact),
        minimumOSVersion: arguments.minimumOS,
        keyID: arguments.keyID,
        signature: Data()
    )
    let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: arguments.privateKey)
    guard privateKey.publicKey.rawRepresentation == arguments.publicKey else {
        throw SignerError.keyMismatch
    }
    let signed = SignedUpdateManifest(
        version: unsigned.version,
        build: unsigned.build,
        downloadURL: unsigned.downloadURL,
        byteCount: unsigned.byteCount,
        sha256: unsigned.sha256,
        minimumOSVersion: unsigned.minimumOSVersion,
        keyID: unsigned.keyID,
        signature: try privateKey.signature(for: unsigned.signingData)
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    try encoder.encode(signed).write(to: arguments.output, options: .atomic)
} catch {
    FileHandle.standardError.write(Data("""
    Usage: iwebit-update-manifest --artifact FILE --version VERSION --build BUILD \
    --minimum-os VERSION --download-url HTTPS_URL --key-id ID \
    --private-key-base64 BASE64 --public-key-base64 BASE64 --output FILE

    Error: \(error)
    """.utf8))
    exit(64)
}

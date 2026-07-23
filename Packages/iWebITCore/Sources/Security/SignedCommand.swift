import CryptoKit
import Foundation

public struct SignedCommand: Codable, Equatable, Sendable {
    public let commandID: UUID
    public let type: String
    public let issuedAt: Date
    public let notBefore: Date
    public let expiresAt: Date
    public let nonce: UUID
    public let targetDeviceID: String
    public let payload: Data
    public let keyID: String
    public let signature: Data

    public init(
        commandID: UUID,
        type: String,
        issuedAt: Date,
        notBefore: Date,
        expiresAt: Date,
        nonce: UUID,
        targetDeviceID: String,
        payload: Data,
        keyID: String,
        signature: Data
    ) {
        self.commandID = commandID
        self.type = type
        self.issuedAt = issuedAt
        self.notBefore = notBefore
        self.expiresAt = expiresAt
        self.nonce = nonce
        self.targetDeviceID = targetDeviceID
        self.payload = payload
        self.keyID = keyID
        self.signature = signature
    }

    public var signingData: Data {
        let fields = [
            commandID.uuidString.lowercased(),
            type,
            String(Int(issuedAt.timeIntervalSince1970)),
            String(Int(notBefore.timeIntervalSince1970)),
            String(Int(expiresAt.timeIntervalSince1970)),
            nonce.uuidString.lowercased(),
            targetDeviceID,
            payload.base64EncodedString(),
            keyID
        ]
        return Data(fields.joined(separator: "\n").utf8)
    }
}

public struct CommandVerifier: Sendable {
    private let publicKeys: [String: Data]
    private let allowedClockSkew: TimeInterval

    public init(publicKeys: [String: Data], allowedClockSkew: TimeInterval = 60) {
        self.publicKeys = publicKeys
        self.allowedClockSkew = allowedClockSkew
    }

    public func verify(_ command: SignedCommand, for deviceID: String, at date: Date = Date()) throws {
        guard command.targetDeviceID == deviceID else {
            throw CoreError.unauthorized
        }
        guard date.addingTimeInterval(allowedClockSkew) >= command.notBefore else {
            throw CoreError.commandNotYetValid
        }
        guard date.addingTimeInterval(-allowedClockSkew) <= command.expiresAt else {
            throw CoreError.commandExpired
        }
        guard let keyData = publicKeys[command.keyID],
              let publicKey = try? Curve25519.Signing.PublicKey(rawRepresentation: keyData),
              publicKey.isValidSignature(command.signature, for: command.signingData) else {
            throw CoreError.signatureInvalid
        }
    }
}

public actor CommandReplayGuard {
    private var acceptedNonces: [UUID: Date] = [:]
    private let retention: TimeInterval

    public init(retention: TimeInterval = 86_400) {
        self.retention = retention
    }

    public func accept(_ command: SignedCommand, at date: Date = Date()) throws {
        acceptedNonces = acceptedNonces.filter { date.timeIntervalSince($0.value) < retention }
        guard acceptedNonces[command.nonce] == nil else {
            throw CoreError.commandReplay
        }
        acceptedNonces[command.nonce] = date
    }
}

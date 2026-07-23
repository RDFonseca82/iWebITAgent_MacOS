import Foundation

public enum CoreError: Error, Equatable {
    case insecureTransport
    case invalidURL
    case invalidResponse
    case unauthorized
    case server(statusCode: Int)
    case signatureMissing
    case signatureInvalid
    case commandExpired
    case commandNotYetValid
    case commandReplay
    case checksumMismatch
    case updateManifestInvalid
    case stateCorrupted
    case unsupportedCommand
    case invalidCommandPayload
    case capabilityUnavailable
}

import CryptoKit
import Foundation

public struct DeviceCredentials: Codable, Equatable, Sendable {
    public let deviceID: String
    public let keyID: String
    public let sharedSecret: Data

    public init(deviceID: String, keyID: String, sharedSecret: Data) {
        self.deviceID = deviceID
        self.keyID = keyID
        self.sharedSecret = sharedSecret
    }
}

public struct RequestAuthenticator: Sendable {
    public static let protocolVersion = "1"

    private let credentials: DeviceCredentials
    private let now: @Sendable () -> Date
    private let nonce: @Sendable () -> UUID

    public init(
        credentials: DeviceCredentials,
        now: @escaping @Sendable () -> Date = { Date() },
        nonce: @escaping @Sendable () -> UUID = { UUID() }
    ) {
        self.credentials = credentials
        self.now = now
        self.nonce = nonce
    }

    public func authenticate(_ request: URLRequest) throws -> URLRequest {
        guard let url = request.url, url.scheme?.lowercased() == "https" else {
            throw CoreError.insecureTransport
        }

        var signedRequest = request
        let timestamp = String(Int(now().timeIntervalSince1970))
        let requestNonce = nonce().uuidString.lowercased()
        let bodyHash = Self.sha256Hex(request.httpBody ?? Data())
        let canonical = Self.canonicalRequest(
            method: request.httpMethod ?? "GET",
            url: url,
            timestamp: timestamp,
            nonce: requestNonce,
            bodyHash: bodyHash
        )
        let signature = HMAC<SHA256>.authenticationCode(
            for: Data(canonical.utf8),
            using: SymmetricKey(data: credentials.sharedSecret)
        )

        signedRequest.setValue(Self.protocolVersion, forHTTPHeaderField: "X-iWebIT-Protocol")
        signedRequest.setValue(credentials.deviceID, forHTTPHeaderField: "X-iWebIT-Device-ID")
        signedRequest.setValue(credentials.keyID, forHTTPHeaderField: "X-iWebIT-Key-ID")
        signedRequest.setValue(timestamp, forHTTPHeaderField: "X-iWebIT-Timestamp")
        signedRequest.setValue(requestNonce, forHTTPHeaderField: "X-iWebIT-Nonce")
        signedRequest.setValue(bodyHash, forHTTPHeaderField: "X-iWebIT-Content-SHA256")
        signedRequest.setValue(Data(signature).base64EncodedString(), forHTTPHeaderField: "X-iWebIT-Signature")
        return signedRequest
    }

    public static func canonicalRequest(
        method: String,
        url: URL,
        timestamp: String,
        nonce: String,
        bodyHash: String
    ) -> String {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let path = components?.percentEncodedPath.isEmpty == false ? components?.percentEncodedPath ?? "/" : "/"
        let query = (components?.queryItems ?? [])
            .sorted {
                if $0.name == $1.name { return ($0.value ?? "") < ($1.value ?? "") }
                return $0.name < $1.name
            }
            .map { "\($0.name)=\($0.value ?? "")" }
            .joined(separator: "&")

        return [
            method.uppercased(),
            path,
            query,
            timestamp,
            nonce.lowercased(),
            bodyHash.lowercased()
        ].joined(separator: "\n")
    }

    public static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

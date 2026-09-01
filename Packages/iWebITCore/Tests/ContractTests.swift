import CryptoKit
import XCTest
@testable import iWebITCore

final class ContractTests: XCTestCase {
    func testDecodesCurrentCompanyContract() throws {
        let response = try decodeFixture("company-response", as: LegacyCompanyResponse.self)
        XCTAssertEqual(response.idSync, "COMPANY-EXAMPLE")
        XCTAssertEqual(response.idCompany, "42")
        XCTAssertEqual(response.appleAgentVersion, "2.0.0")
        XCTAssertEqual(response.timeAlive, 5)
    }

    func testDecodesCurrentDeviceContract() throws {
        let response = try decodeFixture("device-response", as: LegacyDeviceResponse.self)
        XCTAssertEqual(response.uniqueID, "device-example")
        XCTAssertEqual(response.fullSync, 1)
        XCTAssertEqual(response.deviceLocation, 1)
        XCTAssertEqual(response.messageText, "Manutenção agendada")
        XCTAssertEqual(response.setBackground, 1)
        XCTAssertEqual(
            response.backgroundImage,
            "https://agent.iwebit.app/backgrounds/empresa.jpg"
        )
    }

    func testNormalizesConcatenatedSupportObjects() throws {
        let source = try fixtureData("support-response-concatenated")
        let normalized = try LegacyResponseNormalizer.supportArrayData(from: source)
        let responses = try JSONDecoder().decode([LegacySupportResponse].self, from: normalized)
        XCTAssertEqual(responses.count, 2)
        XCTAssertEqual(responses[1].name, "Técnico")
    }

    func testRejectsCleartextProductionEnvironment() {
        XCTAssertThrowsError(try APIEnvironment(baseURL: URL(string: "http://agent.iwebit.app")!)) {
            XCTAssertEqual($0 as? CoreError, .insecureTransport)
        }
    }

    func testAllowsCleartextOnlyForExplicitLocalTests() throws {
        let environment = try APIEnvironment(
            baseURL: URL(string: "http://127.0.0.1:8080")!,
            allowInsecureLocalhostForTests: true
        )
        XCTAssertEqual(environment.baseURL.host, "127.0.0.1")
    }

    private func decodeFixture<T: Decodable>(_ name: String, as type: T.Type) throws -> T {
        try JSONDecoder().decode(type, from: fixtureData(name))
    }

    private func fixtureData(_ name: String) throws -> Data {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json") else {
            XCTFail("Missing fixture \(name)")
            return Data()
        }
        return try Data(contentsOf: url)
    }
}

final class SecurityTests: XCTestCase {
    func testRequestAuthenticationIsDeterministicAndCoversBody() throws {
        let credentials = DeviceCredentials(
            deviceID: "device-1",
            keyID: "key-1",
            sharedSecret: Data("test-secret-with-at-least-32-bytes".utf8)
        )
        let authenticator = RequestAuthenticator(
            credentials: credentials,
            now: { Date(timeIntervalSince1970: 1_700_000_000) },
            nonce: { UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")! }
        )
        var request = URLRequest(url: URL(string: "https://api.iwebit.app/v2/sync?z=2&a=1")!)
        request.httpMethod = "POST"
        request.httpBody = Data("{\"ok\":true}".utf8)

        let signed = try authenticator.authenticate(request)

        XCTAssertEqual(signed.value(forHTTPHeaderField: "X-iWebIT-Device-ID"), "device-1")
        XCTAssertEqual(signed.value(forHTTPHeaderField: "X-iWebIT-Timestamp"), "1700000000")
        XCTAssertEqual(
            signed.value(forHTTPHeaderField: "X-iWebIT-Content-SHA256"),
            RequestAuthenticator.sha256Hex(Data("{\"ok\":true}".utf8))
        )
        XCTAssertFalse((signed.value(forHTTPHeaderField: "X-iWebIT-Signature") ?? "").isEmpty)
    }

    func testVerifiesSignedCommandAndRejectsReplay() async throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        let unsigned = SignedCommand(
            commandID: UUID(),
            type: "fullSync",
            issuedAt: Date(timeIntervalSince1970: 1_700_000_000),
            notBefore: Date(timeIntervalSince1970: 1_699_999_990),
            expiresAt: Date(timeIntervalSince1970: 1_700_000_300),
            nonce: UUID(),
            targetDeviceID: "device-1",
            payload: Data("{}".utf8),
            keyID: "server-2026",
            signature: Data()
        )
        let signature = try privateKey.signature(for: unsigned.signingData)
        let command = SignedCommand(
            commandID: unsigned.commandID,
            type: unsigned.type,
            issuedAt: unsigned.issuedAt,
            notBefore: unsigned.notBefore,
            expiresAt: unsigned.expiresAt,
            nonce: unsigned.nonce,
            targetDeviceID: unsigned.targetDeviceID,
            payload: unsigned.payload,
            keyID: unsigned.keyID,
            signature: signature
        )

        let verifier = CommandVerifier(publicKeys: ["server-2026": privateKey.publicKey.rawRepresentation])
        try verifier.verify(command, for: "device-1", at: Date(timeIntervalSince1970: 1_700_000_010))

        let replayGuard = CommandReplayGuard()
        try await replayGuard.accept(command, at: Date(timeIntervalSince1970: 1_700_000_010))
        do {
            try await replayGuard.accept(command, at: Date(timeIntervalSince1970: 1_700_000_011))
            XCTFail("Expected replay rejection")
        } catch {
            XCTAssertEqual(error as? CoreError, .commandReplay)
        }
    }

    func testVerifiesSignedUpdateManifestAndArtifact() throws {
        let artifact = Data("signed package bytes".utf8)
        let privateKey = Curve25519.Signing.PrivateKey()
        let unsigned = SignedUpdateManifest(
            version: "2.0.0",
            build: "200",
            downloadURL: URL(string: "https://updates.iwebit.app/iWebIT-2.0.0.pkg")!,
            byteCount: Int64(artifact.count),
            sha256: RequestAuthenticator.sha256Hex(artifact),
            minimumOSVersion: "12.0",
            keyID: "updates-2026",
            signature: Data()
        )
        let signature = try privateKey.signature(for: unsigned.signingData)
        let manifest = SignedUpdateManifest(
            version: unsigned.version,
            build: unsigned.build,
            downloadURL: unsigned.downloadURL,
            byteCount: unsigned.byteCount,
            sha256: unsigned.sha256,
            minimumOSVersion: unsigned.minimumOSVersion,
            keyID: unsigned.keyID,
            signature: signature
        )

        let verifier = UpdateVerifier(publicKeys: ["updates-2026": privateKey.publicKey.rawRepresentation])
        XCTAssertNoThrow(try verifier.verifyArtifact(artifact, against: manifest))
        XCTAssertThrowsError(try verifier.verifyArtifact(Data("tampered".utf8), against: manifest))
    }
}

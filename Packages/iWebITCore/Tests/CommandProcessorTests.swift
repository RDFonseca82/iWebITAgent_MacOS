import CryptoKit
import XCTest
@testable import iWebITCore

final class CommandProcessorTests: XCTestCase {
    func testValidCommandIsDispatchedExactlyOnce() async throws {
        let key = Curve25519.Signing.PrivateKey()
        let command = try makeCommand(key: key)
        let handler = RecordingCommandHandler()
        let processor = SignedCommandProcessor(
            deviceID: "device-1",
            verifier: CommandVerifier(
                publicKeys: ["commands-1": key.publicKey.rawRepresentation]
            ),
            handler: handler
        )

        let result = try await processor.process(command)

        XCTAssertEqual(result.status, .completed)
        let firstInvocationCount = await handler.invocationCount()
        XCTAssertEqual(firstInvocationCount, 1)
        do {
            _ = try await processor.process(command)
            XCTFail("Expected replay rejection")
        } catch {
            XCTAssertEqual(error as? CoreError, .commandReplay)
        }
        let replayInvocationCount = await handler.invocationCount()
        XCTAssertEqual(replayInvocationCount, 1)
    }

    func testInvalidSignatureNeverReachesHandler() async throws {
        let trustedKey = Curve25519.Signing.PrivateKey()
        let attackerKey = Curve25519.Signing.PrivateKey()
        let command = try makeCommand(key: attackerKey)
        let handler = RecordingCommandHandler()
        let processor = SignedCommandProcessor(
            deviceID: "device-1",
            verifier: CommandVerifier(
                publicKeys: ["commands-1": trustedKey.publicKey.rawRepresentation]
            ),
            handler: handler
        )

        do {
            _ = try await processor.process(command)
            XCTFail("Expected signature rejection")
        } catch {
            XCTAssertEqual(error as? CoreError, .signatureInvalid)
        }
        let invalidInvocationCount = await handler.invocationCount()
        XCTAssertEqual(invalidInvocationCount, 0)
    }

    private func makeCommand(
        key: Curve25519.Signing.PrivateKey
    ) throws -> SignedCommand {
        let now = Date()
        let unsigned = SignedCommand(
            commandID: UUID(),
            type: RemoteCommandType.restart.rawValue,
            issuedAt: now,
            notBefore: now.addingTimeInterval(-1),
            expiresAt: now.addingTimeInterval(60),
            nonce: UUID(),
            targetDeviceID: "device-1",
            payload: try JSONEncoder().encode(
                RestartCommandPayload(reason: "Security update")
            ),
            keyID: "commands-1",
            signature: Data()
        )
        return SignedCommand(
            commandID: unsigned.commandID,
            type: unsigned.type,
            issuedAt: unsigned.issuedAt,
            notBefore: unsigned.notBefore,
            expiresAt: unsigned.expiresAt,
            nonce: unsigned.nonce,
            targetDeviceID: unsigned.targetDeviceID,
            payload: unsigned.payload,
            keyID: unsigned.keyID,
            signature: try key.signature(for: unsigned.signingData)
        )
    }
}

private actor RecordingCommandHandler: RemoteCommandHandling {
    private var count = 0

    func handle(
        _ command: SignedCommand,
        type: RemoteCommandType
    ) async throws -> RemoteCommandResult {
        count += 1
        return RemoteCommandResult(commandID: command.commandID, status: .completed)
    }

    func invocationCount() -> Int {
        count
    }
}


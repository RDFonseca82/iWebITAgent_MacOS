import XCTest
@testable import iWebITCore

final class AccessCodeStoreTests: XCTestCase {
    func testStoresVerifierAndChecksExactNormalizedCode() throws {
        let store = KeychainAccessCodeStore(
            service: "app.iwebit.tests.\(UUID().uuidString)",
            account: "idsync"
        )
        defer { try? store.delete() }

        try store.save(code: "  COMPANY-123  ")

        XCTAssertTrue(try store.containsVerifier())
        XCTAssertTrue(try store.verify(code: "COMPANY-123"))
        XCTAssertFalse(try store.verify(code: "company-123"))
        XCTAssertFalse(try store.verify(code: "COMPANY-124"))
    }

    func testMissingVerifierDoesNotAuthorize() throws {
        let store = KeychainAccessCodeStore(
            service: "app.iwebit.tests.\(UUID().uuidString)",
            account: "idsync"
        )
        defer { try? store.delete() }

        XCTAssertFalse(try store.containsVerifier())
        XCTAssertFalse(try store.verify(code: "anything"))
    }
}

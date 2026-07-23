import XCTest
@testable import iWebITCore

final class StateStoreTests: XCTestCase {
    func testStateUpdatesAreTypedAndAtomic() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = AgentStateStore(fileURL: directory.appendingPathComponent("state.json"))

        let updated = try await store.update {
            $0.deviceID = "device-1"
            $0.companyID = "42"
        }

        XCTAssertEqual(updated.deviceID, "device-1")
        XCTAssertEqual(try await store.load().companyID, "42")
    }
}

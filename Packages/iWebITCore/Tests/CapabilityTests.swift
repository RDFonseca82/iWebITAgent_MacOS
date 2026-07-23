import XCTest
@testable import iWebITCore

final class CapabilityTests: XCTestCase {
    func testMobileAdministrativeCommandsAreUnavailable() {
        let context = CapabilityContext(platform: .iPadOS, osVersion: "15.0")
        for capability in [RemoteCapability.restart, .shutdown, .removeApplication] {
            let result = AppleCapabilityMatrix.availability(of: capability, for: context)
            XCTAssertFalse(result.isAvailable)
            XCTAssertEqual(result.delivery, .unavailable)
        }
    }

    func testMobileUpdateUsesAppStore() {
        let context = CapabilityContext(platform: .iOS, osVersion: "15.0")
        XCTAssertEqual(
            AppleCapabilityMatrix.availability(of: .packageUpdate, for: context).delivery,
            .appStore
        )
    }

    func testMobileScreenshotIsUnavailable() {
        let context = CapabilityContext(platform: .iOS, osVersion: "15.0")
        let result = AppleCapabilityMatrix.availability(of: .screenshot, for: context)
        XCTAssertFalse(result.isAvailable)
        XCTAssertFalse(result.requiresUserConsent)
        XCTAssertEqual(result.delivery, .unavailable)
    }

    func testMobileLocationIsUserMediated() {
        let context = CapabilityContext(platform: .iPadOS, osVersion: "15.0")
        let result = AppleCapabilityMatrix.availability(of: .location, for: context)
        XCTAssertTrue(result.isAvailable)
        XCTAssertTrue(result.requiresUserConsent)
        XCTAssertEqual(result.delivery, .userMediated)
    }

    func testUnsupportedLegacyOSIsRejected() {
        let context = CapabilityContext(platform: .iOS, osVersion: "14.8")
        XCTAssertFalse(AppleCapabilityMatrix.availability(of: .location, for: context).isAvailable)
    }

    func testMacPackageUpdateUsesNativeAgent() {
        let context = CapabilityContext(platform: .macOS, osVersion: "11.0")
        XCTAssertEqual(AppleCapabilityMatrix.availability(of: .packageUpdate, for: context).delivery, .nativeAgent)
    }
}
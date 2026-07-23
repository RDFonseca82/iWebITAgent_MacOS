import AppKit
import CoreGraphics
import CoreLocation
import Foundation
import iWebITCore

@MainActor
final class UserSessionPrivacyCommandHandler: NSObject, CLLocationManagerDelegate {
    typealias ScreenshotSink = @Sendable (UUID, Data) async throws -> Void
    typealias LocationSink = @Sendable (UUID, CLLocation) async throws -> Void

    private let screenshotSink: ScreenshotSink
    private let locationSink: LocationSink
    private let locationManager = CLLocationManager()
    private var pendingLocationCommandID: UUID?

    init(
        screenshotSink: @escaping ScreenshotSink,
        locationSink: @escaping LocationSink
    ) {
        self.screenshotSink = screenshotSink
        self.locationSink = locationSink
        super.init()
        locationManager.delegate = self
    }

    func handle(_ command: SignedCommand, type: RemoteCommandType) async throws -> RemoteCommandResult {
        switch type {
        case .captureScreen:
            _ = try JSONDecoder().decode(CaptureScreenCommandPayload.self, from: command.payload)
            guard CGPreflightScreenCaptureAccess() || CGRequestScreenCaptureAccess() else {
                return .init(commandID: command.commandID, status: .requiresUserAction, message: "Screen Recording permission is required.")
            }
            guard let image = CGDisplayCreateImage(CGMainDisplayID()) else {
                throw PrivacyCommandError.captureFailed
            }
            let representation = NSBitmapImageRep(cgImage: image)
            guard let data = representation.representation(using: .jpeg, properties: [.compressionFactor: 0.82]) else {
                throw PrivacyCommandError.captureFailed
            }
            try await screenshotSink(command.commandID, data)
            return .init(commandID: command.commandID, status: .completed)

        case .requestLocation:
            let payload = try JSONDecoder().decode(RequestLocationCommandPayload.self, from: command.payload)
            locationManager.desiredAccuracy = max(payload.desiredAccuracyMeters, kCLLocationAccuracyBest)
            pendingLocationCommandID = command.commandID
            locationManager.requestLocation()
            return .init(commandID: command.commandID, status: .acknowledged, message: "Location request started.")

        default:
            throw CoreError.unsupportedCommand
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let commandID = pendingLocationCommandID, let location = locations.last else { return }
        pendingLocationCommandID = nil
        Task { try await locationSink(commandID, location) }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        pendingLocationCommandID = nil
    }
}

enum PrivacyCommandError: Error {
    case captureFailed
}

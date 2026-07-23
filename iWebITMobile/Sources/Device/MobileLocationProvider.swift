import CoreLocation
import Foundation

@MainActor
final class MobileLocationProvider: NSObject, CLLocationManagerDelegate {
    static let shared = MobileLocationProvider()

    private let manager = CLLocationManager()
    private var pending: CheckedContinuation<CLLocation, Error>?
    private(set) var latestAuthorizedLocation: CLLocation?

    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var authorizationDescription: String {
        switch manager.authorizationStatus {
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorizedAlways: return "authorizedAlways"
        case .authorizedWhenInUse: return "authorizedWhenInUse"
        @unknown default: return "unknown"
        }
    }

    func requestOneShot() async throws -> CLLocation {
        guard pending == nil else {
            throw MobileLocationError.requestAlreadyInProgress
        }

        return try await withCheckedThrowingContinuation { continuation in
            pending = continuation
            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedAlways, .authorizedWhenInUse:
                manager.requestLocation()
            case .denied, .restricted:
                finish(with: .failure(MobileLocationError.permissionDenied))
            @unknown default:
                finish(with: .failure(MobileLocationError.unavailable))
            }
        }
    }

    func clearCachedLocation() {
        latestAuthorizedLocation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard pending != nil else { return }
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            finish(with: .failure(MobileLocationError.permissionDenied))
        case .notDetermined:
            break
        @unknown default:
            finish(with: .failure(MobileLocationError.unavailable))
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else {
            finish(with: .failure(MobileLocationError.unavailable))
            return
        }
        latestAuthorizedLocation = location
        finish(with: .success(location))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(with: .failure(error))
    }

    private func finish(with result: Result<CLLocation, Error>) {
        guard let pending else { return }
        self.pending = nil
        pending.resume(with: result)
    }
}

enum MobileLocationError: Error {
    case requestAlreadyInProgress
    case permissionDenied
    case unavailable
}

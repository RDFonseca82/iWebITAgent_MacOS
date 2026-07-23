import Foundation
import iWebITCore
import UIKit

@MainActor
final class MobileRuntime: ObservableObject {
    enum Phase: Equatable {
        case loading
        case enrollmentRequired
        case ready
        case failed(String)
    }

    @Published private(set) var phase: Phase = .loading
    @Published private(set) var tickets: [SupportTicket] = []
    @Published private(set) var isSynchronizing = false
    @Published private(set) var locationSyncMessage: String?

    private let credentialStore = KeychainCredentialStore()
    private let trustStore = KeychainServerTrustStore()
    private var client: SecureAPIClient?
    private var supportRepository: SupportRepository?
    private var syncService: MobileSyncService?
    private var observers: [NSObjectProtocol] = []

    init() {
        observers.append(
            NotificationCenter.default.addObserver(
                forName: .didReceiveAPNSToken,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let token = notification.object as? Data else { return }
                Task { @MainActor [weak self] in
                    await self?.register(pushToken: token)
                }
            }
        )

        Task {
            await configureFromKeychain()
        }
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    func enroll(idSync: String) async {
        phase = .loading
        do {
            let environment = try apiEnvironment()
            let enrollmentClient = EnrollmentAPIClient(environment: environment)
            let result = try await enrollmentClient.enroll(
                DeviceEnrollmentRequest(
                    idSync: idSync,
                    platform: UIDevice.current.userInterfaceIdiom == .pad ? .iPadOS : .iOS,
                    appVersion: appVersion,
                    appBuild: appBuild,
                    vendorIdentifier: UIDevice.current.identifierForVendor
                )
            )
            let credentials = DeviceCredentials(
                deviceID: result.deviceID,
                keyID: result.keyID,
                sharedSecret: result.sharedSecret
            )
            try credentialStore.save(credentials)
            try trustStore.save(
                ServerTrustBundle(
                    commandPublicKeys: result.commandPublicKeys,
                    updatePublicKeys: result.updatePublicKeys
                )
            )
            await activate(credentials: credentials, environment: environment)
        } catch {
            phase = .failed(String(describing: error))
        }
    }

    func synchronize() async {
        guard let syncService else { return }
        isSynchronizing = true
        _ = await syncService.synchronize()
        isSynchronizing = false
    }

    func synchronizeLocationNow() async {
        locationSyncMessage = nil
        isSynchronizing = true
        defer { isSynchronizing = false }
        do {
            _ = try await MobileLocationProvider.shared.requestOneShot()
            defer { MobileLocationProvider.shared.clearCachedLocation() }
            guard let syncService else {
                throw CoreError.unauthorized
            }
            locationSyncMessage = await syncService.synchronize()
                ? "Localização sincronizada com autorização."
                : "Não foi possível sincronizar a localização."
        } catch MobileLocationError.permissionDenied {
            locationSyncMessage = "A permissão de localização está desativada."
        } catch {
            locationSyncMessage = "Não foi possível obter a localização."
        }
    }

    func loadTickets() async {
        guard let supportRepository else { return }
        do {
            tickets = try await supportRepository.tickets()
        } catch {
            phase = .failed(String(describing: error))
        }
    }

    func createTicket(name: String, message: String) async throws {
        guard let supportRepository else {
            throw CoreError.unauthorized
        }
        let ticket = try await supportRepository.create(name: name, message: message)
        tickets.insert(ticket, at: 0)
    }

    func signOut() {
        do {
            try credentialStore.delete()
            try trustStore.delete()
        } catch {}
        client = nil
        supportRepository = nil
        syncService = nil
        tickets = []
        phase = .enrollmentRequired
    }

    private func configureFromKeychain() async {
        do {
            let environment = try apiEnvironment()
            guard let credentials = try credentialStore.load() else {
                phase = .enrollmentRequired
                return
            }
            await activate(credentials: credentials, environment: environment)
        } catch {
            phase = .failed(String(describing: error))
        }
    }

    private func activate(credentials: DeviceCredentials, environment: APIEnvironment) async {
        let client = SecureAPIClient(
            environment: environment,
            authenticator: RequestAuthenticator(credentials: credentials)
        )
        let syncService = MobileSyncService(
            client: client,
            pushTokenAvailable: UIApplication.shared.isRegisteredForRemoteNotifications
        )
        self.client = client
        self.supportRepository = SupportRepository(client: client)
        self.syncService = syncService
        await MobileSyncTrigger.shared.install {
            await syncService.synchronize()
        }
        phase = .ready
        await synchronize()
        await loadTickets()
    }

    private func register(pushToken: Data) async {
        guard let client else { return }
        do {
            await syncService?.setPushTokenAvailable(true)
            try await client.postWithoutResponse(
                "/v2/devices/push-token",
                body: PushTokenRegistration(token: pushToken)
            )
            await synchronize()
        } catch {}
    }

    private func apiEnvironment() throws -> APIEnvironment {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "IWebITAPIBaseURL") as? String,
              let url = URL(string: value) else {
            throw CoreError.invalidURL
        }
        return try APIEnvironment(baseURL: url)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    private var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }
}

private struct PushTokenRegistration: Codable, Sendable {
    let token: Data
}

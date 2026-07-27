import AppKit
import Foundation
import iWebITCore
import UserNotifications

@MainActor
final class MacStoreRuntime: ObservableObject {
    enum Phase: Equatable {
        case loading
        case enrollmentRequired
        case ready
        case failed(String)
    }

    @Published private(set) var phase: Phase = .loading
    @Published private(set) var tickets: [SupportTicket] = []
    @Published private(set) var isSynchronizing = false
    @Published private(set) var syncMessage: String?
    @Published private(set) var supportMessage: String?
    @Published private(set) var lastSuccessfulSyncAt: Date?
    @Published private(set) var notificationAuthorization = "a verificar"

    private let credentialStore = KeychainCredentialStore(
        service: "app.iwebit.mac-store.device-authentication"
    )
    private let trustStore = KeychainServerTrustStore(
        service: "app.iwebit.mac-store.server-trust"
    )
    private var client: SecureAPIClient?
    private var supportRepository: SupportRepository?
    private var syncService: MacStoreSyncService?
    private var pendingPushToken: Data?
    private var observers: [NSObjectProtocol] = []

    init() {
        observers.append(
            NotificationCenter.default.addObserver(
                forName: .macStoreDidReceiveAPNSToken,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let token = notification.object as? Data else { return }
                Task { @MainActor [weak self] in
                    self?.pendingPushToken = token
                    await self?.registerPendingPushToken()
                }
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(
                forName: .macStoreDidRequestSync,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.synchronize()
                }
            }
        )
        Task {
            await configureFromKeychain()
            await refreshNotificationAuthorization()
        }
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    func enroll(idSync: String) async {
        let normalized = idSync.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            phase = .failed("Introduza o ID de sincronização.")
            return
        }

        phase = .loading
        do {
            let environment = try apiEnvironment()
            let enrollmentClient = EnrollmentAPIClient(environment: environment)
            let result = try await enrollmentClient.enroll(
                DeviceEnrollmentRequest(
                    idSync: normalized,
                    platform: .macOS,
                    appVersion: appVersion,
                    appBuild: appBuild,
                    vendorIdentifier: nil
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

    func retry() async {
        phase = .loading
        await configureFromKeychain()
    }

    func synchronize() async {
        guard let syncService, !isSynchronizing else { return }
        isSynchronizing = true
        let succeeded = await syncService.synchronize()
        isSynchronizing = false
        if succeeded {
            lastSuccessfulSyncAt = Date()
            syncMessage = "Sincronização concluída."
        } else {
            syncMessage = "Não foi possível sincronizar. Tente novamente."
        }
        await refreshNotificationAuthorization()
    }

    func loadTickets() async {
        guard let supportRepository else { return }
        do {
            tickets = try await supportRepository.tickets()
            supportMessage = nil
        } catch {
            supportMessage = "Não foi possível obter as ocorrências."
        }
    }

    func createTicket(name: String, message: String) async throws {
        guard let supportRepository else {
            throw CoreError.unauthorized
        }
        let ticket = try await supportRepository.create(name: name, message: message)
        tickets.insert(ticket, at: 0)
        supportMessage = "Pedido enviado ao suporte."
    }

    func requestNotificationPermission() async {
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            NSApplication.shared.registerForRemoteNotifications()
        } catch {
            supportMessage = "Não foi possível ativar as notificações."
        }
        await refreshNotificationAuthorization()
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
        lastSuccessfulSyncAt = nil
        syncMessage = nil
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
        let syncService = MacStoreSyncService(
            client: client,
            credentialStore: credentialStore,
            pushTokenAvailable: pendingPushToken != nil
        )
        self.client = client
        self.supportRepository = SupportRepository(client: client)
        self.syncService = syncService
        phase = .ready
        await registerPendingPushToken()
        await synchronize()
        await loadTickets()
    }

    private func registerPendingPushToken() async {
        guard let token = pendingPushToken, let client else { return }
        do {
            await syncService?.setPushTokenAvailable(true)
            try await client.postWithoutResponse(
                "/v2/devices/push-token",
                body: PushTokenRegistration(token: token)
            )
            pendingPushToken = nil
        } catch {}
    }

    private func refreshNotificationAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            notificationAuthorization = "não solicitada"
        case .denied:
            notificationAuthorization = "desativada"
        case .authorized:
            notificationAuthorization = "ativa"
        case .provisional:
            notificationAuthorization = "provisória"
        @unknown default:
            notificationAuthorization = "desconhecida"
        }
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

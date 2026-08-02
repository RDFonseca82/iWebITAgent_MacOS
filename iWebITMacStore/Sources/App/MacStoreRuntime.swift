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

    private let credentialStore = KeychainLegacyAppleCredentialStore(
        service: "app.iwebit.mac-store.legacy-apple-authentication"
    )
    private let obsoleteCredentialStore = KeychainCredentialStore(
        service: "app.iwebit.mac-store.device-authentication"
    )
    private let obsoleteTrustStore = KeychainServerTrustStore(
        service: "app.iwebit.mac-store.server-trust"
    )
    private var client: LegacyAppleAPIClient?
    private var activeCredentials: LegacyAppleCredentials?
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
            let client = try legacyClient()
            let company = try await client.company(idSync: normalized)
            let credentials = LegacyAppleCredentials(
                idSync: normalized,
                uniqueID: installationIdentifier(),
                idCompany: company.idCompany
            )
            let snapshot = try await MacStoreDeviceCollector().collect(
                deviceID: credentials.uniqueID,
                lastSuccessfulSyncAt: nil,
                pushTokenAvailable: pendingPushToken != nil
            )
            try SnapshotPrivacyValidator().validateMacAppStoreOrigin(snapshot)
            try await client.synchronize(
                snapshot,
                credentials: credentials,
                pushToken: pendingPushToken.map(Self.hex)
            )
            try credentialStore.save(credentials)
            try? obsoleteCredentialStore.delete()
            try? obsoleteTrustStore.delete()
            await activate(credentials: credentials, client: client)
        } catch {
            phase = .failed(userMessage(for: error))
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
        guard let client, let credentials = activeCredentials else { return }
        do {
            tickets = try await client.tickets(uniqueID: credentials.uniqueID)
            supportMessage = nil
        } catch {
            supportMessage = "Não foi possível obter as ocorrências."
        }
    }

    func createTicket(name: String, message: String) async throws {
        guard let client, let credentials = activeCredentials else {
            throw CoreError.unauthorized
        }
        let ticket = try await client.createTicket(
            uniqueID: credentials.uniqueID,
            name: name,
            message: message
        )
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
        try? credentialStore.delete()
        try? obsoleteCredentialStore.delete()
        try? obsoleteTrustStore.delete()
        client = nil
        activeCredentials = nil
        syncService = nil
        pendingPushToken = nil
        tickets = []
        lastSuccessfulSyncAt = nil
        syncMessage = nil
        phase = .enrollmentRequired
    }

    private func configureFromKeychain() async {
        do {
            let client = try legacyClient()
            guard let credentials = try credentialStore.load() else {
                phase = .enrollmentRequired
                return
            }
            await activate(credentials: credentials, client: client)
        } catch {
            phase = .failed(userMessage(for: error))
        }
    }

    private func activate(
        credentials: LegacyAppleCredentials,
        client: LegacyAppleAPIClient
    ) async {
        let syncService = MacStoreSyncService(
            client: client,
            credentialStore: credentialStore,
            pushToken: pendingPushToken
        )
        self.client = client
        self.activeCredentials = credentials
        self.syncService = syncService
        phase = .ready
        await registerPendingPushToken()
        await synchronize()
        await loadTickets()
    }

    private func registerPendingPushToken() async {
        guard let token = pendingPushToken, let syncService else { return }
        await syncService.setPushToken(token)
        if await syncService.synchronize() {
            pendingPushToken = nil
            lastSuccessfulSyncAt = Date()
        }
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

    private func legacyClient() throws -> LegacyAppleAPIClient {
        try LegacyAppleAPIClient(
            syncURL: configuredURL("IWebITAppleSyncURL"),
            apiURL: configuredURL("IWebITLegacyAPIURL"),
            supportURL: configuredURL("IWebITLegacySupportURL")
        )
    }

    private func configuredURL(_ key: String) throws -> URL {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              let url = URL(string: value) else {
            throw CoreError.invalidURL
        }
        return url
    }

    private func installationIdentifier() -> String {
        let key = "app.iwebit.mac-store.installation-identifier"
        if let value = UserDefaults.standard.string(forKey: key), !value.isEmpty {
            return value
        }
        let value = UUID().uuidString.lowercased()
        UserDefaults.standard.set(value, forKey: key)
        return value
    }

    private func userMessage(for error: Error) -> String {
        if let coreError = error as? CoreError {
            switch coreError {
            case .unauthorized:
                return "O IDSYNC não foi aceite. Confirme o código e tente novamente."
            case .server(let statusCode):
                return "O servidor iWebIT respondeu com o erro HTTP \(statusCode)."
            case .invalidResponse:
                return "O servidor iWebIT devolveu uma resposta inválida."
            case .invalidURL, .insecureTransport:
                return "A ligação segura ao servidor iWebIT não está corretamente configurada."
            default:
                break
            }
        }
        if error is URLError {
            return "Não foi possível contactar o servidor iWebIT. Confirme a ligação à Internet."
        }
        return "Não foi possível associar este Mac. Tente novamente."
    }

    private static func hex(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }
}

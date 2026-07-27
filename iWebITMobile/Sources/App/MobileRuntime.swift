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

    private static let lastSyncDefaultsKey = "app.iwebit.mobile.last-successful-sync"
    private static let failedAccessAttemptsKey = "app.iwebit.mobile.failed-access-attempts"
    private static let accessLockedUntilKey = "app.iwebit.mobile.access-locked-until"

    @Published private(set) var phase: Phase = .loading
    @Published private(set) var tickets: [SupportTicket] = []
    @Published private(set) var isSynchronizing = false
    @Published private(set) var locationSyncMessage: String?
    @Published private(set) var lastSuccessfulSyncAt: Date? = UserDefaults.standard.object(
        forKey: MobileRuntime.lastSyncDefaultsKey
    ) as? Date
    @Published private(set) var lastSyncStatus = "ainda não executada"
    @Published private(set) var pushTokenAvailable = UIApplication.shared.isRegisteredForRemoteNotifications

    private let credentialStore = KeychainCredentialStore()
    private let trustStore = KeychainServerTrustStore()
    private let accessCodeStore = KeychainAccessCodeStore(
        service: "app.iwebit.mobile.diagnostics-access"
    )
    private var client: SecureAPIClient?
    private var supportRepository: SupportRepository?
    private var syncService: MobileSyncService?
    private var pendingPushToken: Data?
    private var observers: [NSObjectProtocol] = []

    init() {
        if lastSuccessfulSyncAt != nil {
            lastSyncStatus = "última execução conhecida com sucesso"
        }
        observers.append(
            NotificationCenter.default.addObserver(
                forName: .didReceiveAPNSToken,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let token = notification.object as? Data else { return }
                Task { @MainActor [weak self] in
                    self?.pendingPushToken = token
                    self?.pushTokenAvailable = true
                    await AgentLogger.shared.log(
                        category: "notifications",
                        action: "token-received",
                        message: "Token APNs recebido."
                    )
                    await self?.registerPendingPushToken()
                }
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(
                forName: .didFailAPNSRegistration,
                object: nil,
                queue: .main
            ) { _ in
                Task {
                    await AgentLogger.shared.log(
                        .warning,
                        category: "notifications",
                        action: "registration-failed",
                        message: "O registo APNs falhou."
                    )
                }
            }
        )

        Task {
            await AgentLogger.shared.log(
                category: "lifecycle",
                action: "runtime-start",
                message: "Runtime móvel iniciado."
            )
            await configureFromKeychain()
        }
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    func enroll(idSync: String) async {
        let normalized = idSync.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            phase = .failed("Introduza o IDSYNC.")
            return
        }
        phase = .loading
        await AgentLogger.shared.log(
            category: "enrollment",
            action: "start",
            message: "Associação do dispositivo iniciada."
        )
        do {
            let environment = try apiEnvironment()
            let result = try await requestEnrollment(idSync: normalized, environment: environment)
            let credentials = try saveEnrollment(result, idSync: normalized)
            await AgentLogger.shared.log(
                category: "enrollment",
                action: "success",
                message: "Dispositivo associado com sucesso."
            )
            await activate(credentials: credentials, environment: environment)
        } catch {
            await AgentLogger.shared.log(
                .error,
                category: "enrollment",
                action: "failure",
                message: "A associação falhou (\(String(describing: type(of: error))))."
            )
            phase = .failed(String(describing: error))
        }
    }

    func retryConfiguration() async {
        await AgentLogger.shared.log(
            category: "lifecycle",
            action: "retry",
            message: "Nova tentativa de configuração solicitada."
        )
        phase = .loading
        await configureFromKeychain()
    }

    func synchronize() async {
        guard let syncService, !isSynchronizing else { return }
        isSynchronizing = true
        let succeeded = await syncService.synchronize()
        lastSuccessfulSyncAt = await syncService.lastSuccessfulSyncDate()
        lastSyncStatus = succeeded ? "sucesso" : "falhou"
        isSynchronizing = false
    }

    func synchronizeLocationNow() async {
        locationSyncMessage = nil
        isSynchronizing = true
        await AgentLogger.shared.log(
            category: "location",
            action: "request",
            message: "Sincronização pontual de localização solicitada pelo utilizador."
        )
        defer { isSynchronizing = false }
        do {
            _ = try await MobileLocationProvider.shared.requestOneShot()
            defer { MobileLocationProvider.shared.clearCachedLocation() }
            guard let syncService else { throw CoreError.unauthorized }
            let succeeded = await syncService.synchronize()
            lastSuccessfulSyncAt = await syncService.lastSuccessfulSyncDate()
            lastSyncStatus = succeeded ? "sucesso" : "falhou"
            locationSyncMessage = succeeded
                ? "Localização sincronizada com autorização."
                : "Não foi possível sincronizar a localização."
            await AgentLogger.shared.log(
                succeeded ? .info : .warning,
                category: "location",
                action: "sync-result",
                message: succeeded
                    ? "Localização autorizada sincronizada."
                    : "A sincronização da localização falhou."
            )
        } catch MobileLocationError.permissionDenied {
            locationSyncMessage = "A permissão de localização está desativada."
            await AgentLogger.shared.log(
                .warning,
                category: "location",
                action: "permission-denied",
                message: "A permissão de localização foi negada."
            )
        } catch {
            locationSyncMessage = "Não foi possível obter a localização."
            await AgentLogger.shared.log(
                .error,
                category: "location",
                action: "failure",
                message: "A recolha pontual de localização falhou."
            )
        }
    }

    func loadTickets() async {
        guard let supportRepository else { return }
        await AgentLogger.shared.log(
            category: "support",
            action: "list-start",
            message: "Consulta de ocorrências iniciada."
        )
        do {
            tickets = try await supportRepository.tickets()
            await AgentLogger.shared.log(
                category: "support",
                action: "list-success",
                message: "Ocorrências atualizadas (\(tickets.count))."
            )
        } catch {
            await AgentLogger.shared.log(
                .error,
                category: "support",
                action: "list-failure",
                message: "Não foi possível consultar as ocorrências."
            )
        }
    }

    func createTicket(name: String, message: String) async throws {
        guard let supportRepository else { throw CoreError.unauthorized }
        await AgentLogger.shared.log(
            category: "support",
            action: "create-start",
            message: "Criação de pedido de suporte iniciada."
        )
        do {
            let ticket = try await supportRepository.create(name: name, message: message)
            tickets.insert(ticket, at: 0)
            await AgentLogger.shared.log(
                category: "support",
                action: "create-success",
                message: "Pedido de suporte criado."
            )
        } catch {
            await AgentLogger.shared.log(
                .error,
                category: "support",
                action: "create-failure",
                message: "A criação do pedido de suporte falhou."
            )
            throw error
        }
    }

    func authorizeAccess(idSync: String) async -> Bool {
        let normalized = idSync.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return false }
        guard accessAttemptAllowed else {
            await AgentLogger.shared.log(
                .warning,
                category: "access",
                action: "rate-limited",
                message: "Acesso protegido temporariamente bloqueado após várias tentativas."
            )
            return false
        }
        do {
            if try accessCodeStore.containsVerifier() {
                let authorized = try accessCodeStore.verify(code: normalized)
                if authorized {
                    resetAccessAttempts()
                } else {
                    recordDeniedAccess()
                }
                await AgentLogger.shared.log(
                    authorized ? .info : .warning,
                    category: "access",
                    action: authorized ? "authorized" : "denied",
                    message: authorized
                        ? "Acesso protegido autorizado."
                        : "Tentativa de acesso protegido recusada."
                )
                return authorized
            }

            await AgentLogger.shared.log(
                category: "access",
                action: "migration-start",
                message: "Validação online do IDSYNC para instalação existente."
            )
            let environment = try apiEnvironment()
            let result = try await requestEnrollment(idSync: normalized, environment: environment)
            let credentials = try saveEnrollment(result, idSync: normalized)
            await activate(credentials: credentials, environment: environment)
            resetAccessAttempts()
            await AgentLogger.shared.log(
                category: "access",
                action: "migration-success",
                message: "Verificador de acesso criado para instalação existente."
            )
            return true
        } catch {
            recordDeniedAccess()
            await AgentLogger.shared.log(
                .warning,
                category: "access",
                action: "denied",
                message: "O IDSYNC não autorizou a ação protegida."
            )
            return false
        }
    }

    func diagnostics(idSync: String) async -> MobileDiagnosticsReport? {
        guard await authorizeAccess(idSync: idSync) else { return nil }
        do {
            guard let credentials = try credentialStore.load() else {
                throw CoreError.unauthorized
            }
            await AgentLogger.shared.log(
                category: "diagnostics",
                action: "open",
                message: "Página de diagnóstico aberta."
            )
            return await MobileDiagnosticsBuilder().build(
                credentials: credentials,
                lastSuccessfulSyncAt: lastSuccessfulSyncAt,
                lastSyncStatus: lastSyncStatus,
                pushTokenAvailable: pushTokenAvailable
            )
        } catch {
            await AgentLogger.shared.log(
                .error,
                category: "diagnostics",
                action: "failure",
                message: "Não foi possível criar o diagnóstico."
            )
            return nil
        }
    }

    func signOut(idSync: String) async -> Bool {
        guard await authorizeAccess(idSync: idSync) else { return false }
        do {
            try credentialStore.delete()
            try trustStore.delete()
            try accessCodeStore.delete()
            UserDefaults.standard.removeObject(forKey: Self.lastSyncDefaultsKey)
            client = nil
            supportRepository = nil
            syncService = nil
            tickets = []
            lastSuccessfulSyncAt = nil
            lastSyncStatus = "ainda não executada"
            pushTokenAvailable = false
            phase = .enrollmentRequired
            await AgentLogger.shared.clear()
            await AgentLogger.shared.log(
                category: "access",
                action: "logout",
                message: "Dispositivo desassociado após validação do IDSYNC."
            )
            return true
        } catch {
            await AgentLogger.shared.log(
                .error,
                category: "access",
                action: "logout-failure",
                message: "A desassociação falhou."
            )
            return false
        }
    }

    private func configureFromKeychain() async {
        do {
            let environment = try apiEnvironment()
            guard let credentials = try credentialStore.load() else {
                await AgentLogger.shared.log(
                    category: "lifecycle",
                    action: "enrollment-required",
                    message: "Não existem credenciais guardadas."
                )
                phase = .enrollmentRequired
                return
            }
            await AgentLogger.shared.log(
                category: "lifecycle",
                action: "credentials-loaded",
                message: "Credenciais do dispositivo carregadas do Porta-chaves."
            )
            await activate(credentials: credentials, environment: environment)
        } catch {
            await AgentLogger.shared.log(
                .error,
                category: "lifecycle",
                action: "configuration-failure",
                message: "A configuração a partir do Porta-chaves falhou."
            )
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
            pushTokenAvailable: pushTokenAvailable
        )
        self.client = client
        self.supportRepository = SupportRepository(client: client)
        self.syncService = syncService
        await MobileSyncTrigger.shared.install {
            await syncService.synchronize()
        }
        lastSuccessfulSyncAt = await syncService.lastSuccessfulSyncDate()
        phase = .ready
        await AgentLogger.shared.log(
            category: "lifecycle",
            action: "ready",
            message: "Agente móvel pronto."
        )
        await registerPendingPushToken()
        await synchronize()
        await loadTickets()
    }

    private func requestEnrollment(
        idSync: String,
        environment: APIEnvironment
    ) async throws -> DeviceEnrollmentResponse {
        try await EnrollmentAPIClient(environment: environment).enroll(
            DeviceEnrollmentRequest(
                idSync: idSync,
                platform: UIDevice.current.userInterfaceIdiom == .pad ? .iPadOS : .iOS,
                appVersion: appVersion,
                appBuild: appBuild,
                vendorIdentifier: UIDevice.current.identifierForVendor
            )
        )
    }

    private func saveEnrollment(
        _ result: DeviceEnrollmentResponse,
        idSync: String
    ) throws -> DeviceCredentials {
        let credentials = DeviceCredentials(
            deviceID: result.deviceID,
            keyID: result.keyID,
            sharedSecret: result.sharedSecret
        )
        try accessCodeStore.save(code: idSync)
        try trustStore.save(
            ServerTrustBundle(
                commandPublicKeys: result.commandPublicKeys,
                updatePublicKeys: result.updatePublicKeys
            )
        )
        try credentialStore.save(credentials)
        return credentials
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
            await AgentLogger.shared.log(
                category: "notifications",
                action: "token-registered",
                message: "Token APNs registado no backend."
            )
            await synchronize()
        } catch {
            await AgentLogger.shared.log(
                .error,
                category: "notifications",
                action: "token-registration-failure",
                message: "Não foi possível registar o token APNs."
            )
        }
    }

    private var accessAttemptAllowed: Bool {
        guard let lockedUntil = UserDefaults.standard.object(
            forKey: Self.accessLockedUntilKey
        ) as? Date else {
            return true
        }
        if lockedUntil <= Date() {
            resetAccessAttempts()
            return true
        }
        return false
    }

    private func recordDeniedAccess() {
        let defaults = UserDefaults.standard
        let attempts = defaults.integer(forKey: Self.failedAccessAttemptsKey) + 1
        defaults.set(attempts, forKey: Self.failedAccessAttemptsKey)
        if attempts >= 5 {
            defaults.set(
                Date(timeIntervalSinceNow: 60),
                forKey: Self.accessLockedUntilKey
            )
        }
    }

    private func resetAccessAttempts() {
        UserDefaults.standard.removeObject(forKey: Self.failedAccessAttemptsKey)
        UserDefaults.standard.removeObject(forKey: Self.accessLockedUntilKey)
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

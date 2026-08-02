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

    private let credentialStore = KeychainLegacyAppleCredentialStore()
    private let obsoleteCredentialStore = KeychainCredentialStore()
    private let obsoleteTrustStore = KeychainServerTrustStore()
    private let accessCodeStore = KeychainAccessCodeStore(
        service: "app.iwebit.mobile.diagnostics-access"
    )
    private var client: LegacyAppleAPIClient?
    private var activeCredentials: LegacyAppleCredentials?
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
            let (credentials, client) = try await performEnrollment(idSync: normalized)
            resetAccessAttempts()
            await AgentLogger.shared.log(
                category: "enrollment",
                action: "success",
                message: "Dispositivo associado com sucesso."
            )
            await activate(credentials: credentials, client: client)
        } catch {
            await AgentLogger.shared.log(
                .error,
                category: "enrollment",
                action: "failure",
                message: "A associação falhou (\(String(describing: type(of: error))))."
            )
            phase = .failed(userMessage(for: error))
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
        guard let client, let credentials = activeCredentials else { return }
        await AgentLogger.shared.log(
            category: "support",
            action: "list-start",
            message: "Consulta de ocorrências iniciada."
        )
        do {
            tickets = try await client.tickets(uniqueID: credentials.uniqueID)
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
        guard let client, let credentials = activeCredentials else { throw CoreError.unauthorized }
        await AgentLogger.shared.log(
            category: "support",
            action: "create-start",
            message: "Criação de pedido de suporte iniciada."
        )
        do {
            let ticket = try await client.createTicket(
                uniqueID: credentials.uniqueID,
                name: name,
                message: message
            )
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
            let (credentials, client) = try await performEnrollment(idSync: normalized)
            await activate(credentials: credentials, client: client)
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
            try? obsoleteCredentialStore.delete()
            try? obsoleteTrustStore.delete()
            try accessCodeStore.delete()
            UserDefaults.standard.removeObject(forKey: Self.lastSyncDefaultsKey)
            client = nil
            activeCredentials = nil
            syncService = nil
            tickets = []
            lastSuccessfulSyncAt = nil
            lastSyncStatus = "ainda não executada"
            pushTokenAvailable = false
            pendingPushToken = nil
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
            let client = try legacyClient()
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
            await activate(credentials: credentials, client: client)
        } catch {
            await AgentLogger.shared.log(
                .error,
                category: "lifecycle",
                action: "configuration-failure",
                message: "A configuração a partir do Porta-chaves falhou."
            )
            phase = .failed(userMessage(for: error))
        }
    }

    private func activate(
        credentials: LegacyAppleCredentials,
        client: LegacyAppleAPIClient
    ) async {
        let syncService = MobileSyncService(
            client: client,
            credentialStore: credentialStore,
            pushToken: pendingPushToken,
            pushTokenAvailable: pushTokenAvailable
        )
        self.client = client
        self.activeCredentials = credentials
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

    private func performEnrollment(
        idSync: String
    ) async throws -> (LegacyAppleCredentials, LegacyAppleAPIClient) {
        let client = try legacyClient()
        let uniqueID = UIDevice.current.identifierForVendor?.uuidString.lowercased()
            ?? installationIdentifier()
        let company = try await client.company(idSync: idSync)
        let credentials = LegacyAppleCredentials(
            idSync: idSync,
            uniqueID: uniqueID,
            idCompany: company.idCompany
        )
        let snapshot = try await MobileDeviceCollector().collect(
            deviceID: uniqueID,
            lastSuccessfulSyncAt: lastSuccessfulSyncAt,
            pushTokenAvailable: pendingPushToken != nil || pushTokenAvailable
        )
        try SnapshotPrivacyValidator().validateMobileAppOrigin(snapshot)
        try await client.synchronize(
            snapshot,
            credentials: credentials,
            pushToken: pendingPushToken.map(Self.hex)
        )
        try accessCodeStore.save(code: idSync)
        try credentialStore.save(credentials)
        try? obsoleteCredentialStore.delete()
        try? obsoleteTrustStore.delete()
        return (credentials, client)
    }

    private func registerPendingPushToken() async {
        guard let token = pendingPushToken, let syncService else { return }
        await syncService.setPushToken(token)
        let succeeded = await syncService.synchronize()
        if succeeded {
            pendingPushToken = nil
            pushTokenAvailable = true
            lastSuccessfulSyncAt = await syncService.lastSuccessfulSyncDate()
            lastSyncStatus = "sucesso"
            await AgentLogger.shared.log(
                category: "notifications",
                action: "token-registered",
                message: "Token APNs sincronizado com o backend legado."
            )
        } else {
            await AgentLogger.shared.log(
                .error,
                category: "notifications",
                action: "token-registration-failure",
                message: "Não foi possível sincronizar o token APNs."
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
        let key = "app.iwebit.mobile.installation-identifier"
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
            return "Não foi possível contactar o servidor iWebIT. Confirme a ligação à Internet e tente novamente."
        }
        return "Não foi possível associar o dispositivo. Tente novamente."
    }

    private static func hex(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }
    private var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }
}

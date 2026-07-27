import Foundation
import iWebITCore

actor MobileSyncService {
    private static let lastSyncDefaultsKey = "app.iwebit.mobile.last-successful-sync"

    private let client: SecureAPIClient
    private let collector: MobileDeviceCollector
    private let credentialStore: KeychainCredentialStore
    private var lastSuccessfulSyncAt: Date?
    private var pushTokenAvailable: Bool

    init(
        client: SecureAPIClient,
        collector: MobileDeviceCollector = MobileDeviceCollector(),
        credentialStore: KeychainCredentialStore = KeychainCredentialStore(),
        pushTokenAvailable: Bool = false
    ) {
        self.client = client
        self.collector = collector
        self.credentialStore = credentialStore
        self.pushTokenAvailable = pushTokenAvailable
        self.lastSuccessfulSyncAt = UserDefaults.standard.object(
            forKey: Self.lastSyncDefaultsKey
        ) as? Date
    }

    func setPushTokenAvailable(_ available: Bool) {
        pushTokenAvailable = available
    }

    func lastSuccessfulSyncDate() -> Date? {
        lastSuccessfulSyncAt
    }

    func synchronize() async -> Bool {
        await AgentLogger.shared.log(
            category: "sync",
            action: "start",
            message: "Sincronização iniciada."
        )
        do {
            guard let credentials = try credentialStore.load() else {
                await AgentLogger.shared.log(
                    .warning,
                    category: "sync",
                    action: "credentials",
                    message: "Sincronização cancelada: credenciais indisponíveis."
                )
                return false
            }
            let snapshot = try await collector.collect(
                deviceID: credentials.deviceID,
                lastSuccessfulSyncAt: lastSuccessfulSyncAt,
                pushTokenAvailable: pushTokenAvailable
            )
            try SnapshotPrivacyValidator().validateMobileAppOrigin(snapshot)
            try await client.postWithoutResponse("/v2/devices/snapshots", body: snapshot)
            lastSuccessfulSyncAt = Date()
            UserDefaults.standard.set(lastSuccessfulSyncAt, forKey: Self.lastSyncDefaultsKey)
            await AgentLogger.shared.log(
                category: "sync",
                action: "success",
                message: "Snapshot sincronizado com sucesso."
            )
            return true
        } catch {
            await AgentLogger.shared.log(
                .error,
                category: "sync",
                action: "failure",
                message: "A sincronização falhou (\(String(describing: type(of: error))))."
            )
            return false
        }
    }
}

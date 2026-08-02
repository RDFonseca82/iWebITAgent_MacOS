import Foundation
import iWebITCore

actor MobileSyncService {
    private static let lastSyncDefaultsKey = "app.iwebit.mobile.last-successful-sync"

    private let client: LegacyAppleAPIClient
    private let collector: MobileDeviceCollector
    private let credentialStore: KeychainLegacyAppleCredentialStore
    private var lastSuccessfulSyncAt: Date?
    private var pushToken: String?
    private var pushTokenAvailable: Bool

    init(
        client: LegacyAppleAPIClient,
        collector: MobileDeviceCollector = MobileDeviceCollector(),
        credentialStore: KeychainLegacyAppleCredentialStore = KeychainLegacyAppleCredentialStore(),
        pushToken: Data? = nil,
        pushTokenAvailable: Bool = false
    ) {
        self.client = client
        self.collector = collector
        self.credentialStore = credentialStore
        self.pushToken = pushToken.map(Self.hex)
        self.pushTokenAvailable = pushToken != nil || pushTokenAvailable
        self.lastSuccessfulSyncAt = UserDefaults.standard.object(
            forKey: Self.lastSyncDefaultsKey
        ) as? Date
    }

    func setPushToken(_ token: Data) {
        pushToken = Self.hex(token)
        pushTokenAvailable = true
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
                deviceID: credentials.uniqueID,
                lastSuccessfulSyncAt: lastSuccessfulSyncAt,
                pushTokenAvailable: pushTokenAvailable
            )
            try SnapshotPrivacyValidator().validateMobileAppOrigin(snapshot)
            try await client.synchronize(
                snapshot,
                credentials: credentials,
                pushToken: pushToken
            )
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

    private static func hex(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }
}

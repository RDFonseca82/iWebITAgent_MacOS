import Foundation
import iWebITCore

actor MacStoreSyncService {
    private let client: LegacyAppleAPIClient
    private let collector: MacStoreDeviceCollector
    private let credentialStore: KeychainLegacyAppleCredentialStore
    private var lastSuccessfulSyncAt: Date?
    private var pushToken: String?
    private var pushTokenAvailable: Bool

    init(
        client: LegacyAppleAPIClient,
        collector: MacStoreDeviceCollector = MacStoreDeviceCollector(),
        credentialStore: KeychainLegacyAppleCredentialStore,
        pushToken: Data? = nil
    ) {
        self.client = client
        self.collector = collector
        self.credentialStore = credentialStore
        self.pushToken = pushToken.map(Self.hex)
        self.pushTokenAvailable = pushToken != nil
    }

    func setPushToken(_ token: Data) {
        pushToken = Self.hex(token)
        pushTokenAvailable = true
    }

    func synchronize() async -> Bool {
        do {
            guard let credentials = try credentialStore.load() else { return false }
            let snapshot = try await collector.collect(
                deviceID: credentials.uniqueID,
                lastSuccessfulSyncAt: lastSuccessfulSyncAt,
                pushTokenAvailable: pushTokenAvailable
            )
            try SnapshotPrivacyValidator().validateMacAppStoreOrigin(snapshot)
            try await client.synchronize(
                snapshot,
                credentials: credentials,
                pushToken: pushToken
            )
            lastSuccessfulSyncAt = Date()
            return true
        } catch {
            return false
        }
    }

    private static func hex(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }
}

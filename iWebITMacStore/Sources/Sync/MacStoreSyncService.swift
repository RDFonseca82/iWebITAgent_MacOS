import Foundation
import iWebITCore

actor MacStoreSyncService {
    private let client: SecureAPIClient
    private let collector: MacStoreDeviceCollector
    private let credentialStore: KeychainCredentialStore
    private var lastSuccessfulSyncAt: Date?
    private var pushTokenAvailable: Bool

    init(
        client: SecureAPIClient,
        collector: MacStoreDeviceCollector = MacStoreDeviceCollector(),
        credentialStore: KeychainCredentialStore,
        pushTokenAvailable: Bool = false
    ) {
        self.client = client
        self.collector = collector
        self.credentialStore = credentialStore
        self.pushTokenAvailable = pushTokenAvailable
    }

    func setPushTokenAvailable(_ available: Bool) {
        pushTokenAvailable = available
    }

    func synchronize() async -> Bool {
        do {
            guard let credentials = try credentialStore.load() else { return false }
            let snapshot = try await collector.collect(
                deviceID: credentials.deviceID,
                lastSuccessfulSyncAt: lastSuccessfulSyncAt,
                pushTokenAvailable: pushTokenAvailable
            )
            try SnapshotPrivacyValidator().validateMacAppStoreOrigin(snapshot)
            try await client.postWithoutResponse("/v2/devices/snapshots", body: snapshot)
            lastSuccessfulSyncAt = Date()
            return true
        } catch {
            return false
        }
    }
}

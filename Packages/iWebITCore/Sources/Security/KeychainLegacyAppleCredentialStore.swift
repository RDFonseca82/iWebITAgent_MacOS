import Foundation
import Security

public struct KeychainLegacyAppleCredentialStore: Sendable {
    private let service: String
    private let account: String

    public init(
        service: String = "app.iwebit.legacy-apple-authentication",
        account: String = "legacy-apple-credentials"
    ) {
        self.service = service
        self.account = account
    }

    public func load() throws -> LegacyAppleCredentials? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else {
            throw CoreError.stateCorrupted
        }
        return try JSONDecoder().decode(LegacyAppleCredentials.self, from: data)
    }

    public func save(_ credentials: LegacyAppleCredentials) throws {
        let data = try JSONEncoder().encode(credentials)
        let status = SecItemUpdate(
            baseQuery as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )
        if status == errSecItemNotFound {
            var insert = baseQuery
            insert[kSecValueData as String] = data
            insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            guard SecItemAdd(insert as CFDictionary, nil) == errSecSuccess else {
                throw CoreError.stateCorrupted
            }
        } else if status != errSecSuccess {
            throw CoreError.stateCorrupted
        }
    }

    public func delete() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw CoreError.stateCorrupted
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: kCFBooleanFalse as Any
        ]
    }
}

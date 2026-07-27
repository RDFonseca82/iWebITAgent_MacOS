import CryptoKit
import Foundation
import Security

public struct KeychainAccessCodeStore: Sendable {
    private struct Record: Codable {
        let salt: Data
        let digest: Data
    }

    private let service: String
    private let account: String

    public init(
        service: String = "app.iwebit.diagnostics-access",
        account: String = "idsync-verifier"
    ) {
        self.service = service
        self.account = account
    }

    public func save(code: String) throws {
        let normalized = normalize(code)
        guard !normalized.isEmpty else { throw CoreError.invalidCommandPayload }

        var salt = Data(count: 32)
        let status = salt.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
        }
        guard status == errSecSuccess else { throw CoreError.stateCorrupted }

        let record = Record(salt: salt, digest: digest(code: normalized, salt: salt))
        let data = try JSONEncoder().encode(record)
        let update = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, update as CFDictionary)

        if updateStatus == errSecItemNotFound {
            var insert = baseQuery
            insert[kSecValueData as String] = data
            insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            guard SecItemAdd(insert as CFDictionary, nil) == errSecSuccess else {
                throw CoreError.stateCorrupted
            }
        } else if updateStatus != errSecSuccess {
            throw CoreError.stateCorrupted
        }
    }

    public func verify(code: String) throws -> Bool {
        guard let record = try load() else { return false }
        let candidate = digest(code: normalize(code), salt: record.salt)
        guard candidate.count == record.digest.count else { return false }
        return zip(candidate, record.digest).reduce(UInt8(0)) {
            $0 | ($1.0 ^ $1.1)
        } == 0
    }

    public func containsVerifier() throws -> Bool {
        try load() != nil
    }

    public func delete() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw CoreError.stateCorrupted
        }
    }

    private func load() throws -> Record? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else {
            throw CoreError.stateCorrupted
        }
        return try JSONDecoder().decode(Record.self, from: data)
    }

    private func digest(code: String, salt: Data) -> Data {
        var input = salt
        input.append(contentsOf: code.utf8)
        return Data(SHA256.hash(data: input))
    }

    private func normalize(_ code: String) -> String {
        code.trimmingCharacters(in: .whitespacesAndNewlines)
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

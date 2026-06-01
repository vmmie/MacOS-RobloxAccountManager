import Foundation
import Security

public enum KeychainError: LocalizedError, Equatable {
    case unexpectedStatus(OSStatus)
    case itemNotFound
    case invalidData

    public var errorDescription: String? {
        switch self {
        case let .unexpectedStatus(status):
            "Keychain operation failed with status \(status)."
        case .itemNotFound:
            "The requested Keychain item was not found."
        case .invalidData:
            "The Keychain item could not be decoded."
        }
    }
}

public protocol SecretStore: Sendable {
    func readSecret(accountID: UUID) throws -> AccountSecret?
    func saveSecret(_ secret: AccountSecret, accountID: UUID) throws
    func deleteSecret(accountID: UUID) throws
}

public struct KeychainStore: SecretStore {
    private let service: String

    public init(service: String = "com.github.vmmie.MacOS-RobloxAccountManager") {
        self.service = service
    }

    public func readSecret(accountID: UUID) throws -> AccountSecret? {
        var query = baseQuery(accountID: accountID)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw KeychainError.unexpectedStatus(status) }
        guard let data = result as? Data else { throw KeychainError.invalidData }
        return try JSONCoding.decoder.decode(AccountSecret.self, from: data)
    }

    public func saveSecret(_ secret: AccountSecret, accountID: UUID) throws {
        let data = try JSONCoding.encoder.encode(secret)
        let query = baseQuery(accountID: accountID)
        let update: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if updateStatus == errSecSuccess { return }
        guard updateStatus == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(updateStatus)
        }

        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let addStatus = SecItemAdd(add as CFDictionary, nil)
        guard addStatus == errSecSuccess else { throw KeychainError.unexpectedStatus(addStatus) }
    }

    public func deleteSecret(accountID: UUID) throws {
        let status = SecItemDelete(baseQuery(accountID: accountID) as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound { return }
        throw KeychainError.unexpectedStatus(status)
    }

    private func baseQuery(accountID: UUID) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accountID.uuidString
        ]
    }
}


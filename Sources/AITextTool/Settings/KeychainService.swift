// KeychainService.swift
// AITextTool
//
// macOS Keychain access using Security framework (SecItem* APIs).
// Service name groups all entries under "com.aitexttool".

import Foundation
import Security
import os

// MARK: - KeychainService

final class KeychainService: KeychainServiceProtocol, @unchecked Sendable {
    /// Keychain service name that groups all AITextTool entries.
    private let serviceName: String

    init(serviceName: String = "com.aitexttool") {
        self.serviceName = serviceName
    }

    // MARK: - KeychainServiceProtocol

    func save(key: String, data: Data) throws {
        // Attempt to update first; if the item doesn't exist, add it.
        let query = baseQuery(for: key)

        let updateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)

        if updateStatus == errSecItemNotFound {
            // Item does not exist yet — add it
            var addQuery = query
            addQuery[kSecValueData as String] = data
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                Logger.settings.error("Keychain save failed with status \(addStatus)")
                throw AppError.keychainWriteFailed
            }
        } else if updateStatus != errSecSuccess {
            Logger.settings.error("Keychain update failed with status \(updateStatus)")
            throw AppError.keychainWriteFailed
        }
    }

    func read(key: String) throws -> Data? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            Logger.settings.error("Keychain read failed with status \(status)")
            throw AppError.keychainReadFailed
        }

        return result as? Data
    }

    func delete(key: String) throws {
        let query = baseQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)

        // errSecItemNotFound is not an error — the key simply didn't exist
        guard status == errSecSuccess || status == errSecItemNotFound else {
            Logger.settings.error("Keychain delete failed with status \(status)")
            throw AppError.keychainWriteFailed
        }
    }

    // MARK: - Private

    private func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
    }
}

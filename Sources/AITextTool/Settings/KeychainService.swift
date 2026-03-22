// KeychainService.swift
// AITextTool
//
// macOS Keychain access using Security framework.

import Foundation

final class KeychainService: KeychainServiceProtocol {
    private let serviceName = "com.aitexttool.keychain"

    func set(_ value: String, for key: String) throws {
        // TODO: Implement SecItemAdd/Update
    }

    func get(for key: String) throws -> String? {
        // TODO: Implement SecItemCopyMatching
        nil
    }

    func delete(for key: String) throws {
        // TODO: Implement SecItemDelete
    }
}

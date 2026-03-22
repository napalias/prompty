// KeychainServiceProtocol.swift
// AITextTool
//
// Protocol for secure storage in macOS Keychain.

import Foundation

/// Protocol for secure API key storage in macOS Keychain.
/// All operations throw on Keychain errors.
protocol KeychainServiceProtocol: Sendable {
    /// Stores data for the given key. Overwrites if the key already exists.
    func save(key: String, data: Data) throws

    /// Retrieves data for the given key, or nil if not found.
    func read(key: String) throws -> Data?

    /// Deletes the entry for the given key. No-op if key does not exist.
    func delete(key: String) throws
}

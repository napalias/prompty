// KeychainServiceProtocol.swift
// AITextTool

import Foundation

/// Protocol for secure API key storage in macOS Keychain.
protocol KeychainServiceProtocol {
    /// Stores a string value for the given key.
    func set(_ value: String, for key: String) throws
    /// Retrieves a string value for the given key.
    func get(for key: String) throws -> String?
    /// Deletes the value for the given key.
    func delete(for key: String) throws
}

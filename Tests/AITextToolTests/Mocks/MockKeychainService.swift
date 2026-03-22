// MockKeychainService.swift
// AITextToolTests
//
// In-memory mock for KeychainServiceProtocol. No real Keychain access.

import Foundation
@testable import AITextTool

final class MockKeychainService: KeychainServiceProtocol, @unchecked Sendable {
    private var store: [String: Data] = [:]
    var saveCallCount = 0
    var readCallCount = 0
    var deleteCallCount = 0

    /// If set, all operations throw this error.
    var stubbedError: Error?

    func save(key: String, data: Data) throws {
        saveCallCount += 1
        if let error = stubbedError { throw error }
        store[key] = data
    }

    func read(key: String) throws -> Data? {
        readCallCount += 1
        if let error = stubbedError { throw error }
        return store[key]
    }

    func delete(key: String) throws {
        deleteCallCount += 1
        if let error = stubbedError { throw error }
        store.removeValue(forKey: key)
    }
}

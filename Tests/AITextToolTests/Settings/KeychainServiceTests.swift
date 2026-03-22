// KeychainServiceTests.swift
// AITextToolTests
//
// Tests KeychainService using a unique service name per test run
// to avoid polluting the real Keychain.

import XCTest
@testable import AITextTool

final class KeychainServiceTests: XCTestCase {
    private var service: KeychainService!
    private var serviceName: String!

    override func setUp() {
        super.setUp()
        // Unique service name per test run prevents cross-test contamination
        serviceName = "com.aitexttool.test.\(UUID().uuidString)"
        service = KeychainService(serviceName: serviceName)
    }

    override func tearDown() {
        // Clean up all test entries from the Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName as Any
        ]
        SecItemDelete(query as CFDictionary)
        service = nil
        super.tearDown()
    }

    // MARK: - test_saveAndRead

    func test_saveAndRead() throws {
        let testData = Data("test-api-key-12345".utf8)

        try service.save(key: "api_key_anthropic", data: testData)

        let retrieved = try service.read(key: "api_key_anthropic")
        XCTAssertEqual(retrieved, testData)
    }

    // MARK: - test_delete

    func test_delete() throws {
        let testData = Data("delete-me".utf8)
        try service.save(key: "temp_key", data: testData)

        // Verify it exists
        XCTAssertNotNil(try service.read(key: "temp_key"))

        // Delete
        try service.delete(key: "temp_key")

        // Verify it's gone
        let result = try service.read(key: "temp_key")
        XCTAssertNil(result)
    }

    // MARK: - test_readNonExistent_returnsNil

    func test_readNonExistent_returnsNil() throws {
        let result = try service.read(key: "nonexistent_key")
        XCTAssertNil(result)
    }

    // MARK: - test_updateExisting

    func test_updateExisting() throws {
        let originalData = Data("original-value".utf8)
        let updatedData = Data("updated-value".utf8)

        try service.save(key: "update_key", data: originalData)
        XCTAssertEqual(try service.read(key: "update_key"), originalData)

        // Overwrite with new value
        try service.save(key: "update_key", data: updatedData)
        XCTAssertEqual(try service.read(key: "update_key"), updatedData)
    }

    // MARK: - test_deleteNonExistent_doesNotThrow

    func test_deleteNonExistent_doesNotThrow() throws {
        // Deleting a key that doesn't exist should not throw
        XCTAssertNoThrow(try service.delete(key: "never_existed"))
    }

    // MARK: - test_saveAndRead_multipleKeys

    func test_saveAndRead_multipleKeys() throws {
        let anthropicData = Data("sk-ant-12345".utf8)
        let openaiData = Data("sk-openai-67890".utf8)

        try service.save(key: "api_key_anthropic", data: anthropicData)
        try service.save(key: "api_key_openai", data: openaiData)

        XCTAssertEqual(try service.read(key: "api_key_anthropic"), anthropicData)
        XCTAssertEqual(try service.read(key: "api_key_openai"), openaiData)
    }

    // MARK: - test_saveEmptyData

    func test_saveEmptyData() throws {
        let emptyData = Data()
        try service.save(key: "empty_key", data: emptyData)
        let result = try service.read(key: "empty_key")
        XCTAssertEqual(result, emptyData)
    }
}

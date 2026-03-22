// AIProviderManagerTests.swift
// AITextToolTests
//
// Tests for AIProviderManager — all providers are mocked.

import XCTest
@testable import AITextTool

@MainActor
final class AIProviderManagerTests: XCTestCase {

    // MARK: - Active Provider

    func test_activeProvider_returnsConfigured() {
        let mock = MockAIProvider()
        mock.mockIsConfigured = true

        let manager = AIProviderManager(providers: [mock])
        manager.activeProviderID = "mock"

        XCTAssertNotNil(manager.activeProvider)
        XCTAssertEqual(manager.activeProvider?.id, "mock")
    }

    func test_activeProvider_returnsNilWhenNoMatch() {
        let manager = AIProviderManager(providers: [])
        manager.activeProviderID = "nonexistent"

        XCTAssertNil(manager.activeProvider)
    }

    // MARK: - Stream Delegation

    func test_stream_delegatesToActive() async throws {
        let mock = MockAIProvider()
        mock.stubbedTokens = ["Hello", " world"]

        let manager = AIProviderManager(providers: [mock])
        manager.activeProviderID = "mock"

        let request = AIRequest(
            systemPrompt: nil,
            userPrompt: "Test",
            selectedText: "text",
            history: []
        )

        var tokens: [String] = []
        let stream = manager.stream(request: request)
        for try await token in stream {
            tokens.append(token)
        }

        XCTAssertEqual(tokens, ["Hello", " world"])
    }

    func test_stream_throwsWhenProviderMissing() async {
        let manager = AIProviderManager(providers: [])
        manager.activeProviderID = "nonexistent"

        let request = AIRequest(
            systemPrompt: nil,
            userPrompt: "Test",
            selectedText: "text",
            history: []
        )

        let stream = manager.stream(request: request)
        do {
            for try await _ in stream {}
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(
                error as? AppError,
                AppError.providerNotConfigured(
                    providerID: "nonexistent"
                )
            )
        }
    }

    func test_stream_throwsWhenNotConfigured() async {
        let mock = MockAIProvider()
        mock.mockIsConfigured = false

        let manager = AIProviderManager(providers: [mock])
        manager.activeProviderID = "mock"

        let request = AIRequest(
            systemPrompt: nil,
            userPrompt: "Test",
            selectedText: "text",
            history: []
        )

        let stream = manager.stream(request: request)
        do {
            for try await _ in stream {}
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(
                error as? AppError,
                AppError.providerNotConfigured(providerID: "mock")
            )
        }
    }

    // MARK: - Set Active Provider

    func test_setActiveProvider_changesActive() {
        let providerA = NamedMockProvider(
            providerID: "provider-a",
            name: "Provider A"
        )
        let providerB = NamedMockProvider(
            providerID: "provider-b",
            name: "Provider B"
        )

        let manager = AIProviderManager(
            providers: [providerA, providerB]
        )
        manager.activeProviderID = "provider-a"
        XCTAssertEqual(manager.activeProvider?.id, "provider-a")

        manager.activeProviderID = "provider-b"
        XCTAssertEqual(manager.activeProvider?.id, "provider-b")
    }

    // MARK: - Has Configured

    func test_hasAnyConfiguredProvider_true() {
        let mock = MockAIProvider()
        mock.mockIsConfigured = true

        let manager = AIProviderManager(providers: [mock])
        XCTAssertTrue(manager.hasAnyConfiguredProvider)
    }

    func test_hasAnyConfiguredProvider_false() {
        let mock = MockAIProvider()
        mock.mockIsConfigured = false

        let manager = AIProviderManager(providers: [mock])
        XCTAssertFalse(manager.hasAnyConfiguredProvider)
    }
}

// MARK: - Test Helper

/// Wraps a provider with custom ID for multi-provider tests.
private final class NamedMockProvider: AIProviderProtocol,
    @unchecked Sendable {
    let id: String
    let displayName: String
    var isConfigured: Bool { true }

    init(providerID: String, name: String) {
        self.id = providerID
        self.displayName = name
    }

    func stream(
        request: AIRequest
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { $0.finish() }
    }
}

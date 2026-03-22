// MockAIProvider.swift
// PromptyTests
//
// Mock AI provider for testing. Returns stubbed tokens or errors.

@testable import Prompty

final class MockAIProvider: AIProviderProtocol, @unchecked Sendable {
    let id = "mock"
    let displayName = "Mock"
    var mockIsConfigured = true
    var isConfigured: Bool { mockIsConfigured }

    /// Tokens to yield when stream() is called.
    var stubbedTokens: [String] = ["Hello", " world"]
    /// If set, stream() throws this error instead.
    var stubbedError: Error?
    /// Captures the last request for assertion.
    var lastReceivedRequest: AIRequest?
    /// Count of stream() calls.
    var streamCallCount = 0

    func stream(
        request: AIRequest
    ) -> AsyncThrowingStream<String, Error> {
        lastReceivedRequest = request
        streamCallCount += 1
        let tokens = stubbedTokens
        let error = stubbedError

        return AsyncThrowingStream { continuation in
            Task {
                if let error {
                    continuation.finish(throwing: error)
                    return
                }
                for token in tokens {
                    continuation.yield(token)
                }
                continuation.finish()
            }
        }
    }
}

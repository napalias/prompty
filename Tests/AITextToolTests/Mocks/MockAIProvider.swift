// MockAIProvider.swift
// AITextToolTests

@testable import AITextTool

final class MockAIProvider: AIProviderProtocol, @unchecked Sendable {
    let id = "mock"
    let displayName = "Mock"
    var mockIsConfigured = true
    var isConfigured: Bool { mockIsConfigured }

    var stubbedTokens: [String] = ["Hello", " world"]
    var stubbedError: Error?

    func stream(request: AIRequest) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                if let error = self.stubbedError {
                    continuation.finish(throwing: error)
                    return
                }
                for token in self.stubbedTokens {
                    continuation.yield(token)
                }
                continuation.finish()
            }
        }
    }
}

// AnthropicProvider.swift
// AITextTool
//
// Claude API key mode provider.

import Foundation

final class AnthropicProvider: AIProviderProtocol {
    let id = "anthropic-api"
    let displayName = "Claude (API Key)"

    var isConfigured: Bool {
        // TODO: Check Keychain for API key
        false
    }

    func stream(request: AIRequest) -> AsyncThrowingStream<String, Error> {
        // TODO: Implement Anthropic API streaming
        AsyncThrowingStream { $0.finish() }
    }
}

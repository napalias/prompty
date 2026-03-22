// OpenAIProvider.swift
// AITextTool
//
// OpenAI API key mode provider. Also supports OpenAI-compatible endpoints.

import Foundation

final class OpenAIProvider: AIProviderProtocol {
    let id = "openai"
    let displayName = "ChatGPT (API Key)"

    var isConfigured: Bool {
        // TODO: Check Keychain for API key
        false
    }

    func stream(request: AIRequest) -> AsyncThrowingStream<String, Error> {
        // TODO: Implement OpenAI API streaming
        AsyncThrowingStream { $0.finish() }
    }
}

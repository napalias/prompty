// AnthropicOAuthProvider.swift
// AITextTool
//
// Claude Pro Subscription mode via OAuth sidecar.

import Foundation

final class AnthropicOAuthProvider: AIProviderProtocol {
    let id = "anthropic-oauth"
    let displayName = "Claude (Pro Subscription)"

    var isConfigured: Bool {
        // TODO: Check Keychain for OAuth token
        false
    }

    func stream(request: AIRequest) -> AsyncThrowingStream<String, Error> {
        // TODO: Implement sidecar communication
        AsyncThrowingStream { $0.finish() }
    }
}

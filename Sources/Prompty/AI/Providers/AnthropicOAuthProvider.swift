// AnthropicOAuthProvider.swift
// Prompty
//
// Claude Pro Subscription mode via OAuth sidecar.

import Foundation

final class AnthropicOAuthProvider: AIProviderProtocol {
    let id = "anthropic-oauth"
    let displayName = "Claude (Pro Subscription)"

    /// Always returns false until W3-2 sidecar task implements OAuth token storage.
    var isConfigured: Bool {
        false
    }

    /// Stub: returns an empty stream. Will be replaced by sidecar communication in W3-2.
    func stream(request: AIRequest) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { $0.finish() }
    }
}

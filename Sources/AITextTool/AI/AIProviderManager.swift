// AIProviderManager.swift
// AITextTool
//
// Holds all registered providers and delegates to the active one.

import Foundation

@Observable
@MainActor
final class AIProviderManager {
    private(set) var providers: [any AIProviderProtocol] = []
    var activeProviderID: String = ""

    var activeProvider: (any AIProviderProtocol)? {
        providers.first { $0.id == activeProviderID }
    }

    /// Whether at least one provider has valid configuration (21E).
    var hasAnyConfiguredProvider: Bool {
        providers.contains { $0.isConfigured }
    }

    /// Streams from the active provider, throwing if not configured.
    nonisolated func stream(
        request: AIRequest
    ) -> AsyncThrowingStream<String, Error> {
        // TODO: Implement provider delegation with retry logic
        AsyncThrowingStream { continuation in
            continuation.finish(
                throwing: AppError.providerNotConfigured(
                    providerID: "none"
                )
            )
        }
    }
}

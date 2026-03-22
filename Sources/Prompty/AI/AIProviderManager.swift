// AIProviderManager.swift
// Prompty
//
// Holds all registered providers, selects active one, delegates stream().
// Protocol-based for testability.

import Foundation
import os

// MARK: - AIProviderManagerProtocol

/// Abstraction for the provider manager, enabling mock injection.
@MainActor
protocol AIProviderManagerProtocol: AnyObject {
    var activeProviderID: String { get }
    func stream(
        request: AIRequest
    ) -> AsyncThrowingStream<String, Error>
}

// MARK: - AIProviderManager

@Observable
@MainActor
final class AIProviderManager: AIProviderManagerProtocol {
    private(set) var providers: [any AIProviderProtocol] = []
    var activeProviderID: String = ""

    var activeProvider: (any AIProviderProtocol)? {
        providers.first { $0.id == activeProviderID }
    }

    /// Whether at least one provider has valid configuration (21E).
    var hasAnyConfiguredProvider: Bool {
        providers.contains { $0.isConfigured }
    }

    // MARK: - Init

    init(providers: [any AIProviderProtocol] = []) {
        self.providers = providers
        self.activeProviderID = providers
            .first { $0.isConfigured }?.id ?? ""
    }

    // MARK: - Provider Registration

    func register(_ provider: any AIProviderProtocol) {
        providers.append(provider)
        if activeProviderID.isEmpty && provider.isConfigured {
            activeProviderID = provider.id
        }
    }

    // MARK: - Streaming

    /// Streams from the active provider, throwing if not configured.
    func stream(
        request: AIRequest
    ) -> AsyncThrowingStream<String, Error> {
        guard let provider = activeProvider else {
            return AsyncThrowingStream { continuation in
                continuation.finish(
                    throwing: AppError.providerNotConfigured(
                        providerID: self.activeProviderID
                    )
                )
            }
        }

        guard provider.isConfigured else {
            return AsyncThrowingStream { continuation in
                continuation.finish(
                    throwing: AppError.providerNotConfigured(
                        providerID: provider.id
                    )
                )
            }
        }

        return provider.stream(request: request)
    }
}

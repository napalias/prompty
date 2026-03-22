// AIProviderProtocol.swift
// AITextTool

import Foundation

/// Core abstraction for all AI providers.
/// All providers must be Sendable for use across actor boundaries.
protocol AIProviderProtocol: Sendable {
    /// Unique identifier for this provider (e.g. "anthropic-api", "openai").
    var id: String { get }
    /// Human-readable display name (e.g. "Claude (API Key)").
    var displayName: String { get }
    /// Returns false if required configuration (API key, etc.) is missing.
    var isConfigured: Bool { get }
    /// Streams response tokens. Throws AppError on failure.
    func stream(request: AIRequest) -> AsyncThrowingStream<String, Error>
}

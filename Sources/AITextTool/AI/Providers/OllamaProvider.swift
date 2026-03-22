// OllamaProvider.swift
// AITextTool
//
// Ollama local REST API provider.

import Foundation

final class OllamaProvider: AIProviderProtocol {
    let id = "ollama"
    let displayName = "Ollama (Local)"

    var isConfigured: Bool {
        // TODO: Ping localhost:11434
        false
    }

    func stream(request: AIRequest) -> AsyncThrowingStream<String, Error> {
        // TODO: Implement Ollama NDJSON streaming
        AsyncThrowingStream { $0.finish() }
    }
}

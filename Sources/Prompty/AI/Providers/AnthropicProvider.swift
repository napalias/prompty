// AnthropicProvider.swift
// Prompty
//
// Claude API key mode provider. Streams via SSE from the Messages API.

import Foundation
import os

// MARK: - URLSessionProtocol

/// Abstraction over URLSession for testability — allows injecting mock responses.
protocol URLSessionProtocol: Sendable {
    func bytes(
        for request: URLRequest
    ) async throws -> (URLSession.AsyncBytes, URLResponse)
}

extension URLSession: URLSessionProtocol {
    func bytes(
        for request: URLRequest
    ) async throws -> (URLSession.AsyncBytes, URLResponse) {
        try await bytes(for: request, delegate: nil)
    }
}

// MARK: - AnthropicProvider

final class AnthropicProvider: AIProviderProtocol, @unchecked Sendable {

    let id = "anthropic-api"
    let displayName = "Claude (API Key)"

    private let apiKey: @Sendable () -> String
    private let model: @Sendable () -> String
    private let session: URLSessionProtocol

    private static let endpoint = URL(
        string: "https://api.anthropic.com/v1/messages"
    )!

    // MARK: - Init

    /// - Parameters:
    ///   - apiKey: Closure returning the current API key from Keychain.
    ///   - model: Closure returning the model name.
    ///   - session: URLSession (or mock) for network requests.
    init(
        apiKey: @escaping @Sendable () -> String,
        model: @escaping @Sendable () -> String = {
            ModelConstants.Anthropic.defaultModel
        },
        session: URLSessionProtocol = URLSession.shared
    ) {
        self.apiKey = apiKey
        self.model = model
        self.session = session
    }

    var isConfigured: Bool {
        !apiKey().isEmpty
    }

    // MARK: - Streaming

    func stream(
        request aiRequest: AIRequest
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let urlRequest = try self.buildRequest(aiRequest)
                    let (bytes, response) = try await self.session.bytes(
                        for: urlRequest
                    )
                    try self.validateResponse(response)
                    for try await line in bytes.lines {
                        let parsed = SSEParser.extractData(from: line)
                        switch parsed {
                        case .data(let json):
                            if let token = self.extractToken(from: json) {
                                continuation.yield(token)
                            }
                            if json.contains("\"message_stop\"") {
                                continuation.finish()
                                return
                            }
                        case .done:
                            continuation.finish()
                            return
                        case .skip:
                            continue
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Request Building

    private func buildRequest(
        _ aiRequest: AIRequest
    ) throws -> URLRequest {
        var urlRequest = URLRequest(url: Self.endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 30
        urlRequest.setValue(
            apiKey(),
            forHTTPHeaderField: "x-api-key"
        )
        urlRequest.setValue(
            "application/json",
            forHTTPHeaderField: "content-type"
        )
        urlRequest.setValue(
            "2023-06-01",
            forHTTPHeaderField: "anthropic-version"
        )

        var messages: [[String: String]] = []
        for msg in aiRequest.history where msg.role != .system {
            messages.append([
                "role": msg.role.rawValue,
                "content": msg.content
            ])
        }

        let userContent = aiRequest.userPrompt + "\n\n"
            + aiRequest.selectedText
        messages.append(["role": "user", "content": userContent])

        var body: [String: Any] = [
            "model": model(),
            "max_tokens": 4096,
            "stream": true,
            "messages": messages
        ]

        if let systemPrompt = aiRequest.systemPrompt,
           !systemPrompt.isEmpty {
            body["system"] = systemPrompt
        }

        urlRequest.httpBody = try JSONSerialization.data(
            withJSONObject: body
        )
        return urlRequest
    }

    // MARK: - Response Validation

    private func validateResponse(
        _ response: URLResponse
    ) throws {
        guard let http = response as? HTTPURLResponse else {
            return
        }
        switch http.statusCode {
        case 200...299:
            return
        case 401:
            throw AppError.apiKeyInvalid(providerID: id)
        case 429:
            throw AppError.rateLimitExceeded(providerID: id)
        default:
            throw AppError.apiError(
                providerID: id,
                message: "HTTP \(http.statusCode)"
            )
        }
    }

    // MARK: - Token Extraction

    /// Extracts text delta from Anthropic SSE JSON.
    /// Format: {"type":"content_block_delta","delta":{"type":"text_delta","text":"TOKEN"}}
    private func extractToken(from json: String) -> String? {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(
                  with: data
              ) as? [String: Any],
              let delta = obj["delta"] as? [String: Any],
              let text = delta["text"] as? String else {
            return nil
        }
        return text
    }
}

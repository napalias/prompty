// OpenAIProvider.swift
// Prompty
//
// OpenAI API key mode provider. Streams via SSE from chat completions.
// Supports custom base URL for Groq, LM Studio, and other
// OpenAI-compatible endpoints (19J).

import Foundation
import os

final class OpenAIProvider: AIProviderProtocol, @unchecked Sendable {

    let id = "openai"
    let displayName = "ChatGPT (API Key)"

    private let apiKey: @Sendable () -> String
    private let model: @Sendable () -> String
    private let customBaseURL: @Sendable () -> String?
    private let session: URLSessionProtocol

    private static let defaultBaseURL = "https://api.openai.com/v1"

    // MARK: - Init

    /// - Parameters:
    ///   - apiKey: Closure returning the current API key.
    ///   - model: Closure returning the model name.
    ///   - customBaseURL: Optional custom base URL (19J).
    ///   - session: URLSession (or mock) for network requests.
    init(
        apiKey: @escaping @Sendable () -> String,
        model: @escaping @Sendable () -> String = {
            ModelConstants.OpenAI.defaultModel
        },
        customBaseURL: @escaping @Sendable () -> String? = { nil },
        session: URLSessionProtocol = URLSession.shared
    ) {
        self.apiKey = apiKey
        self.model = model
        self.customBaseURL = customBaseURL
        self.session = session
    }

    var isConfigured: Bool {
        // Custom base URL without API key is valid for local servers
        if let base = customBaseURL(), !base.isEmpty {
            return endpoint != nil
        }
        return !apiKey().isEmpty
    }

    // MARK: - Endpoint

    private var endpoint: URL? {
        let base: String
        if let custom = customBaseURL(),
           !custom.trimmingCharacters(in: .whitespaces).isEmpty {
            base = custom.trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(
                    in: CharacterSet(charactersIn: "/")
                )
        } else {
            base = Self.defaultBaseURL
        }
        return URL(string: base + "/chat/completions")
    }

    // MARK: - Streaming

    func stream(
        request aiRequest: AIRequest
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let url = self.endpoint else {
                        continuation.finish(
                            throwing: AppError.providerNotConfigured(
                                providerID: self.id
                            )
                        )
                        return
                    }
                    let urlRequest = try self.buildRequest(
                        aiRequest, url: url
                    )
                    let (bytes, response) = try await self.session
                        .bytes(for: urlRequest)
                    try self.validateResponse(response)
                    for try await line in bytes.lines {
                        let parsed = SSEParser.extractData(from: line)
                        switch parsed {
                        case .data(let json):
                            if let token = self.extractToken(
                                from: json
                            ) {
                                continuation.yield(token)
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
        _ aiRequest: AIRequest,
        url: URL
    ) throws -> URLRequest {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 30
        urlRequest.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        let key = apiKey()
        if !key.isEmpty {
            urlRequest.setValue(
                "Bearer \(key)",
                forHTTPHeaderField: "Authorization"
            )
        }

        var messages: [[String: String]] = []

        if let systemPrompt = aiRequest.systemPrompt,
           !systemPrompt.isEmpty {
            messages.append([
                "role": "system",
                "content": systemPrompt
            ])
        }

        for msg in aiRequest.history where msg.role != .system {
            messages.append([
                "role": msg.role.rawValue,
                "content": msg.content
            ])
        }

        let userContent = aiRequest.userPrompt + "\n\n"
            + aiRequest.selectedText
        messages.append(["role": "user", "content": userContent])

        let body: [String: Any] = [
            "model": model(),
            "stream": true,
            "messages": messages,
            "stream_options": ["include_usage": true]
        ]

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

    /// Extracts content delta from OpenAI SSE JSON.
    /// Format: {"choices":[{"delta":{"content":"TOKEN"}}]}
    private func extractToken(from json: String) -> String? {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(
                  with: data
              ) as? [String: Any],
              let choices = obj["choices"] as? [[String: Any]],
              let first = choices.first,
              let delta = first["delta"] as? [String: Any],
              let content = delta["content"] as? String else {
            return nil
        }
        return content
    }
}

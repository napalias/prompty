// OllamaProvider.swift
// AITextTool
//
// Ollama local REST API provider. Streams NDJSON (not SSE).
// Handles model-not-found error (18I).

import Foundation
import os

final class OllamaProvider: AIProviderProtocol, @unchecked Sendable {

    let id = "ollama"
    let displayName = "Ollama (Local)"

    private let model: @Sendable () -> String
    private let session: URLSessionProtocol
    private let baseURL: String

    private static let defaultBaseURL = "http://localhost:11434"

    // MARK: - Init

    /// - Parameters:
    ///   - model: Closure returning the model name.
    ///   - session: URLSession (or mock) for network requests.
    ///   - baseURL: Ollama server base URL.
    init(
        model: @escaping @Sendable () -> String = { "llama3.2" },
        session: URLSessionProtocol = URLSession.shared,
        baseURL: String = defaultBaseURL
    ) {
        self.model = model
        self.session = session
        self.baseURL = baseURL
    }

    // MARK: - Configuration

    /// Ollama needs no API key; reachability is checked at stream time.
    var isConfigured: Bool {
        true
    }

    // MARK: - Streaming

    func stream(
        request aiRequest: AIRequest
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let urlRequest = try self.buildRequest(aiRequest)
                    let (bytes, response) = try await self.session
                        .bytes(for: urlRequest)
                    try self.validateResponse(response)
                    for try await line in bytes.lines {
                        guard !line.isEmpty else { continue }
                        guard let data = line.data(using: .utf8),
                              let obj =
                                  try? JSONSerialization.jsonObject(
                                      with: data
                                  ) as? [String: Any] else {
                            continue
                        }

                        // Error in response JSON (model not found)
                        if let error = obj["error"] as? String {
                            if error.contains("not found") {
                                continuation.finish(
                                    throwing:
                                        AppError.ollamaModelNotFound(
                                            modelName: self.model()
                                        )
                                )
                            } else {
                                continuation.finish(
                                    throwing: AppError.apiError(
                                        providerID: self.id,
                                        message: error
                                    )
                                )
                            }
                            return
                        }

                        // Extract token from NDJSON line
                        if let message = obj["message"]
                            as? [String: Any],
                           let content = message["content"]
                            as? String,
                           !content.isEmpty {
                            continuation.yield(content)
                        }

                        // Done signal
                        if let done = obj["done"] as? Bool, done {
                            continuation.finish()
                            return
                        }
                    }
                    continuation.finish()
                } catch let urlError as URLError
                    where urlError.code == .cannotConnectToHost
                    || urlError.code == .networkConnectionLost {
                    continuation.finish(
                        throwing: AppError.ollamaNotRunning
                    )
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
        guard let url = URL(
            string: baseURL + "/api/chat"
        ) else {
            throw AppError.providerNotConfigured(providerID: id)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 10
        urlRequest.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

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
            "messages": messages
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
        case 404:
            throw AppError.ollamaModelNotFound(modelName: model())
        default:
            throw AppError.apiError(
                providerID: id,
                message: "HTTP \(http.statusCode)"
            )
        }
    }
}

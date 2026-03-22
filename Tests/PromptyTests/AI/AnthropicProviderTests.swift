// AnthropicProviderTests.swift
// PromptyTests
//
// Tests for AnthropicProvider using MockURLSession.

import XCTest
@testable import Prompty

final class AnthropicProviderTests: XCTestCase {

    private var mockSession: MockURLSession!
    private var provider: AnthropicProvider!
    private let testKey = "sk-ant-test-key-12345"

    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        provider = AnthropicProvider(
            apiKey: { [testKey] in testKey },
            session: mockSession
        )
    }

    // MARK: - isConfigured

    func test_isConfigured_falseWhenKeyIsEmpty() {
        let empty = AnthropicProvider(
            apiKey: { "" },
            session: mockSession
        )
        XCTAssertFalse(empty.isConfigured)
    }

    func test_isConfigured_trueWhenKeyIsSet() {
        XCTAssertTrue(provider.isConfigured)
    }

    // MARK: - Headers

    func test_stream_sendsCorrectHeaders() async throws {
        mockSession.responseLines = [
            #"data: {"type":"message_stop"}"#
        ]

        let stream = provider.stream(request: makeRequest())
        for try await _ in stream {}

        let req = try XCTUnwrap(mockSession.lastRequest)
        XCTAssertEqual(
            req.value(forHTTPHeaderField: "x-api-key"),
            testKey
        )
        XCTAssertEqual(
            req.value(forHTTPHeaderField: "content-type"),
            "application/json"
        )
        XCTAssertEqual(
            req.value(forHTTPHeaderField: "anthropic-version"),
            "2023-06-01"
        )
        XCTAssertEqual(req.httpMethod, "POST")
    }

    // MARK: - Token Parsing

    func test_stream_parsesTokens() async throws {
        mockSession.responseLines = [
            #"data: {"type":"content_block_delta","delta":{"type":"text_delta","text":"Hello"}}"#,
            #"data: {"type":"content_block_delta","delta":{"type":"text_delta","text":" world"}}"#,
            #"data: {"type":"message_stop"}"#
        ]

        var tokens: [String] = []
        let stream = provider.stream(request: makeRequest())
        for try await token in stream {
            tokens.append(token)
        }

        XCTAssertEqual(tokens, ["Hello", " world"])
    }

    // MARK: - Error Handling

    func test_stream_handlesError_401() async {
        mockSession.statusCode = 401
        mockSession.responseLines = [""]

        let stream = provider.stream(request: makeRequest())
        do {
            for try await _ in stream {}
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(
                error as? AppError,
                AppError.apiKeyInvalid(providerID: "anthropic-api")
            )
        }
    }

    func test_stream_handlesError_429() async {
        mockSession.statusCode = 429
        mockSession.responseLines = [""]

        let stream = provider.stream(request: makeRequest())
        do {
            for try await _ in stream {}
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(
                error as? AppError,
                AppError.rateLimitExceeded(
                    providerID: "anthropic-api"
                )
            )
        }
    }

    func test_stream_handlesError_500() async {
        mockSession.statusCode = 500
        mockSession.responseLines = [""]

        let stream = provider.stream(request: makeRequest())
        do {
            for try await _ in stream {}
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(
                error as? AppError,
                AppError.apiError(
                    providerID: "anthropic-api",
                    message: "HTTP 500"
                )
            )
        }
    }

    // MARK: - Request Body

    func test_stream_sendsCorrectRequestBody() async throws {
        mockSession.responseLines = [
            #"data: {"type":"message_stop"}"#
        ]

        let request = AIRequest(
            systemPrompt: "Be helpful",
            userPrompt: "Fix grammar",
            selectedText: "Hello wrold",
            history: []
        )

        let stream = provider.stream(request: request)
        for try await _ in stream {}

        let req = try XCTUnwrap(mockSession.lastRequest)
        let bodyData = try XCTUnwrap(req.httpBody)
        let body = try XCTUnwrap(
            JSONSerialization.jsonObject(
                with: bodyData
            ) as? [String: Any]
        )

        XCTAssertEqual(
            body["model"] as? String,
            "claude-opus-4-5"
        )
        XCTAssertEqual(body["stream"] as? Bool, true)
        XCTAssertEqual(body["max_tokens"] as? Int, 4096)
        XCTAssertEqual(body["system"] as? String, "Be helpful")

        let messages = try XCTUnwrap(
            body["messages"] as? [[String: String]]
        )
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0]["role"], "user")
        XCTAssertTrue(
            messages[0]["content"]?.contains("Fix grammar") ?? false
        )
    }

    // MARK: - Helpers

    private func makeRequest() -> AIRequest {
        AIRequest(
            systemPrompt: nil,
            userPrompt: "Test prompt",
            selectedText: "Test text",
            history: []
        )
    }
}

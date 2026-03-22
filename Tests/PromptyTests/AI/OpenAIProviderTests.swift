// OpenAIProviderTests.swift
// PromptyTests
//
// Tests for OpenAIProvider using MockURLSession.

import XCTest
@testable import Prompty

final class OpenAIProviderTests: XCTestCase {

    private var mockSession: MockURLSession!
    private var provider: OpenAIProvider!
    private let testKey = "sk-openai-test-key"

    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        provider = OpenAIProvider(
            apiKey: { [testKey] in testKey },
            session: mockSession
        )
    }

    // MARK: - isConfigured

    func test_isConfigured_falseWhenKeyIsEmpty() {
        let empty = OpenAIProvider(
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
        mockSession.responseLines = ["data: [DONE]"]

        let stream = provider.stream(request: makeRequest())
        for try await _ in stream {}

        let req = try XCTUnwrap(mockSession.lastRequest)
        XCTAssertEqual(
            req.value(forHTTPHeaderField: "Authorization"),
            "Bearer \(testKey)"
        )
        XCTAssertEqual(
            req.value(forHTTPHeaderField: "Content-Type"),
            "application/json"
        )
        XCTAssertEqual(req.httpMethod, "POST")
    }

    // MARK: - Request Format

    func test_stream_sendsCorrectFormat() async throws {
        mockSession.responseLines = ["data: [DONE]"]

        let request = AIRequest(
            systemPrompt: "Be concise",
            userPrompt: "Summarise",
            selectedText: "Long text here",
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

        XCTAssertEqual(body["model"] as? String, "gpt-4o")
        XCTAssertEqual(body["stream"] as? Bool, true)

        let messages = try XCTUnwrap(
            body["messages"] as? [[String: String]]
        )
        XCTAssertEqual(messages[0]["role"], "system")
        XCTAssertEqual(messages[0]["content"], "Be concise")
        XCTAssertEqual(messages[1]["role"], "user")
    }

    // MARK: - Token Parsing

    func test_stream_parsesChunks() async throws {
        mockSession.responseLines = [
            #"data: {"choices":[{"delta":{"content":"Hi"}}]}"#,
            #"data: {"choices":[{"delta":{"content":" there"}}]}"#,
            "data: [DONE]"
        ]

        var tokens: [String] = []
        let stream = provider.stream(request: makeRequest())
        for try await token in stream {
            tokens.append(token)
        }

        XCTAssertEqual(tokens, ["Hi", " there"])
    }

    // MARK: - Custom Base URL (19J)

    func test_stream_customBaseURL() async throws {
        let groq = OpenAIProvider(
            apiKey: { "groq-key" },
            customBaseURL: {
                "https://api.groq.com/openai/v1"
            },
            session: mockSession
        )
        XCTAssertTrue(groq.isConfigured)

        mockSession.responseLines = ["data: [DONE]"]

        let stream = groq.stream(request: makeRequest())
        for try await _ in stream {}

        let req = try XCTUnwrap(mockSession.lastRequest)
        XCTAssertEqual(
            req.url?.absoluteString,
            "https://api.groq.com/openai/v1/chat/completions"
        )
    }

    func test_stream_customBaseURL_noKeyRequired() {
        let local = OpenAIProvider(
            apiKey: { "" },
            customBaseURL: { "http://localhost:1234/v1" },
            session: mockSession
        )
        XCTAssertTrue(local.isConfigured)
    }

    // MARK: - Error Handling

    func test_stream_throwsAPIKeyInvalid_on401() async {
        mockSession.statusCode = 401
        mockSession.responseLines = [""]

        let stream = provider.stream(request: makeRequest())
        do {
            for try await _ in stream {}
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(
                error as? AppError,
                AppError.apiKeyInvalid(providerID: "openai")
            )
        }
    }

    func test_stream_throwsRateLimitExceeded_on429() async {
        mockSession.statusCode = 429
        mockSession.responseLines = [""]

        let stream = provider.stream(request: makeRequest())
        do {
            for try await _ in stream {}
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(
                error as? AppError,
                AppError.rateLimitExceeded(providerID: "openai")
            )
        }
    }

    func test_stream_throwsAPIError_on4xx() async {
        mockSession.statusCode = 400
        mockSession.responseLines = [""]

        let stream = provider.stream(request: makeRequest())
        do {
            for try await _ in stream {}
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(
                error as? AppError,
                AppError.apiError(
                    providerID: "openai",
                    message: "HTTP 400"
                )
            )
        }
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

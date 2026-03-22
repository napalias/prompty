// OllamaProviderTests.swift
// AITextToolTests
//
// Tests for OllamaProvider using MockURLSession.

import XCTest
@testable import AITextTool

final class OllamaProviderTests: XCTestCase {

    private var mockSession: MockURLSession!
    private var provider: OllamaProvider!

    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        provider = OllamaProvider(
            model: { "llama3.2" },
            session: mockSession
        )
    }

    // MARK: - Token Parsing (NDJSON)

    func test_stream_parsesJSONLines() async throws {
        mockSession.responseLines = [
            #"{"message":{"role":"assistant","content":"Hello"},"done":false}"#,
            #"{"message":{"role":"assistant","content":" there"},"done":false}"#,
            #"{"done":true}"#
        ]

        var tokens: [String] = []
        let stream = provider.stream(request: makeRequest())
        for try await token in stream {
            tokens.append(token)
        }

        XCTAssertEqual(tokens, ["Hello", " there"])
    }

    func test_stream_completesOnDoneTrue() async throws {
        mockSession.responseLines = [
            #"{"message":{"role":"assistant","content":"Hi"},"done":false}"#,
            #"{"done":true}"#,
            #"{"message":{"role":"assistant","content":"extra"},"done":false}"#
        ]

        var tokens: [String] = []
        let stream = provider.stream(request: makeRequest())
        for try await token in stream {
            tokens.append(token)
        }

        XCTAssertEqual(tokens, ["Hi"])
    }

    // MARK: - Model Not Found (18I)

    func test_stream_modelNotFound_via404() async {
        mockSession.statusCode = 404
        mockSession.responseLines = [""]

        let stream = provider.stream(request: makeRequest())
        do {
            for try await _ in stream {}
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(
                error as? AppError,
                AppError.ollamaModelNotFound(modelName: "llama3.2")
            )
        }
    }

    func test_stream_modelNotFound_viaErrorJSON() async {
        mockSession.responseLines = [
            #"{"error":"model 'llama3.2' not found, try pulling it first"}"#
        ]

        let stream = provider.stream(request: makeRequest())
        do {
            for try await _ in stream {}
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(
                error as? AppError,
                AppError.ollamaModelNotFound(modelName: "llama3.2")
            )
        }
    }

    // MARK: - Connection Errors

    func test_stream_throwsOllamaNotRunning() async {
        mockSession.errorToThrow = URLError(.cannotConnectToHost)

        let stream = provider.stream(request: makeRequest())
        do {
            for try await _ in stream {}
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(
                error as? AppError,
                AppError.ollamaNotRunning
            )
        }
    }

    // MARK: - Request Body

    func test_stream_sendsCorrectRequestBody() async throws {
        mockSession.responseLines = [#"{"done":true}"#]

        let request = AIRequest(
            systemPrompt: "Be helpful",
            userPrompt: "Explain",
            selectedText: "Swift concurrency",
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

        XCTAssertEqual(body["model"] as? String, "llama3.2")
        XCTAssertEqual(body["stream"] as? Bool, true)

        let messages = try XCTUnwrap(
            body["messages"] as? [[String: String]]
        )
        XCTAssertEqual(messages[0]["role"], "system")
        XCTAssertEqual(messages[0]["content"], "Be helpful")
        XCTAssertEqual(messages[1]["role"], "user")
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

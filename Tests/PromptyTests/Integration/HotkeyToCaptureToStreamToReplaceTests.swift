// HotkeyToCaptureToStreamToReplaceTests.swift
// PromptyTests
//
// Full flow integration test using all mocks.

import XCTest
@testable import Prompty

final class HotkeyToCaptureToStreamToReplaceTests: XCTestCase {

    // MARK: - Full Flow

    func test_fullFlow_hotkeyToReplace() async throws {
        // 1. Configure mocks
        let mockCapture = MockTextCaptureService()
        let mockProvider = MockAIProvider()
        let mockReplace = MockTextReplaceService()

        let capturedText = "Hello world"
        mockCapture.mockText = capturedText
        mockProvider.stubbedTokens = ["Good", "bye", " world"]

        // 2. Simulate hotkey fire -> capture text
        let text = try await mockCapture.capture()
        XCTAssertEqual(text, capturedText)

        // 3. Update app state with captured text
        await MainActor.run {
            let appState = AppState()
            appState.reset(capturedText: text)
            XCTAssertEqual(appState.capturedText, capturedText)
        }

        // 4. Build AI request and stream
        let request = AIRequest(
            systemPrompt: nil,
            userPrompt: "Fix grammar",
            selectedText: text,
            history: []
        )

        var streamedResult = ""
        let stream = mockProvider.stream(request: request)
        for try await token in stream {
            streamedResult += token
        }

        XCTAssertEqual(streamedResult, "Goodbye world")
        XCTAssertEqual(mockProvider.streamCallCount, 1)
        XCTAssertEqual(mockProvider.lastReceivedRequest?.selectedText, capturedText)

        // 5. Replace text in source app
        try await mockReplace.replace(
            with: streamedResult,
            in: nil,
            pasteMode: .plain
        )

        XCTAssertEqual(mockReplace.replacedText, "Goodbye world")
        XCTAssertEqual(mockReplace.replacedPasteMode, .plain)
    }

    // MARK: - Cancellation

    func test_streamCancellation_cleanupComplete() async throws {
        let mockCapture = MockTextCaptureService()
        let mockProvider = MockAIProvider()
        let mockReplace = MockTextReplaceService()

        // 1. Capture text
        mockCapture.mockText = "Some text"
        let text = try await mockCapture.capture()

        // 2. Start streaming and cancel via AppState
        await MainActor.run {
            let appState = AppState()
            appState.reset(capturedText: text)

            let streamTask = Task<Void, Never> {
                let request = AIRequest(
                    systemPrompt: nil,
                    userPrompt: "Translate",
                    selectedText: text,
                    history: []
                )
                let stream = mockProvider.stream(request: request)
                do {
                    for try await token in stream {
                        appState.streamingTokens += token
                    }
                } catch {
                    // Expected cancellation
                }
            }

            appState.startStreaming(task: streamTask)
            XCTAssertTrue(appState.isStreaming)

            // 3. Cancel streaming
            appState.cancelStreaming()

            XCTAssertFalse(appState.isStreaming)
            XCTAssertNil(appState.streamingTask)
        }

        // 4. Verify no text was replaced (cancelled before replace)
        XCTAssertNil(mockReplace.replacedText)
    }

    // MARK: - Error Cases

    func test_captureFailure_doesNotStream() async {
        let mockCapture = MockTextCaptureService()
        let mockProvider = MockAIProvider()

        mockCapture.mockError = .noTextSelected

        do {
            _ = try await mockCapture.capture()
            XCTFail("Expected capture to throw")
        } catch {
            XCTAssertEqual(error as? AppError, .noTextSelected)
        }

        // Provider should never be called
        XCTAssertEqual(mockProvider.streamCallCount, 0)
    }
}

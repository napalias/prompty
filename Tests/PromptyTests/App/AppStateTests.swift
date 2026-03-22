// AppStateTests.swift
// PromptyTests
//
// Tests for AppState property defaults and reset() behavior.

import Foundation
import Testing
@testable import Prompty

@MainActor
@Suite("AppState")
struct AppStateTests {

    // MARK: - Default Values

    @Test("Properties have correct defaults on init")
    func test_init_propertiesHaveCorrectDefaults() {
        let state = AppState()

        #expect(state.capturedText == "")
        #expect(state.selectedPrompt == nil)
        #expect(state.customPromptInput == "")
        #expect(state.capturedTextWasTruncated == false)
        #expect(state.capturedTextOriginalLength == 0)

        #expect(state.streamingTokens == "")
        #expect(state.isStreaming == false)
        #expect(state.isWaitingForFirstToken == false)
        #expect(state.streamingError == nil)
        #expect(state.lastResponseTokens == nil)
        #expect(state.streamingTask == nil)

        #expect(state.panelMode == .promptPicker)
        #expect(state.panelModeSessionRenderOverride == nil)
        #expect(state.isVisible == false)

        #expect(state.conversationHistory.isEmpty)
        #expect(state.currentSession == nil)
    }

    // MARK: - reset()

    @Test("reset() clears all transient state")
    func test_reset_clearsTransientState() {
        let state = AppState()

        // Populate with non-default values
        state.capturedText = "old text"
        state.selectedPrompt = Prompt(
            id: .init(),
            title: "Test",
            icon: "star",
            template: "{text}",
            resultMode: .replace,
            renderMode: .plain,
            pasteMode: .plain,
            providerOverride: nil,
            systemPromptOverride: nil,
            isBuiltIn: false,
            isHidden: false,
            sortOrder: 0,
            lastUsedAt: nil
        )
        state.customPromptInput = "custom input"
        state.streamingTokens = "some tokens"
        state.isStreaming = true
        state.isWaitingForFirstToken = true
        state.streamingError = .noTextSelected
        state.lastResponseTokens = TokenUsage(
            inputTokens: 10,
            outputTokens: 20,
            providerID: "test"
        )
        state.panelMode = .streaming
        state.panelModeSessionRenderOverride = .code
        state.conversationHistory = [
            AIMessage(role: .user, content: "hello")
        ]

        // Reset with new text
        state.reset(capturedText: "new text")

        #expect(state.capturedText == "new text")
        #expect(state.capturedTextWasTruncated == false)
        #expect(state.capturedTextOriginalLength == "new text".count)

        #expect(state.streamingTokens == "")
        #expect(state.isStreaming == false)
        #expect(state.isWaitingForFirstToken == false)
        #expect(state.streamingError == nil)
        #expect(state.streamingTask == nil)
        #expect(state.lastResponseTokens == nil)

        #expect(state.panelMode == .promptPicker)
        #expect(state.panelModeSessionRenderOverride == nil)
        #expect(state.selectedPrompt == nil)
        #expect(state.customPromptInput == "")

        #expect(state.conversationHistory.isEmpty)
    }

    @Test("reset() with empty string sets empty captured text")
    func test_reset_withEmptyString_setsEmptyCapturedText() {
        let state = AppState()
        state.capturedText = "something"
        state.reset(capturedText: "")

        #expect(state.capturedText == "")
        #expect(state.capturedTextOriginalLength == 0)
    }

    @Test("reset() does not clear currentSession")
    func test_reset_doesNotClearCurrentSession() {
        let state = AppState()
        let session = ConversationSession(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            originalText: "test",
            providerID: "test-provider",
            promptTitle: "Test Prompt",
            messages: [],
            finalResult: nil
        )
        state.currentSession = session

        state.reset(capturedText: "new text")

        // currentSession is NOT reset by reset() per spec 18B/20W
        #expect(state.currentSession != nil)
        #expect(state.currentSession?.id == session.id)
    }

    // MARK: - Streaming Mutations

    @Test("startStreaming sets isStreaming and stores task")
    func test_startStreaming_setsIsStreamingAndStoresTask() {
        let state = AppState()
        let task = Task {}

        state.startStreaming(task: task)

        #expect(state.isStreaming == true)
        #expect(state.streamingTask != nil)
    }

    @Test("cancelStreaming cancels task and clears streaming state")
    func test_cancelStreaming_cancelsTaskAndClearsState() {
        let state = AppState()
        let task = Task {}
        state.startStreaming(task: task)

        state.cancelStreaming()

        #expect(state.isStreaming == false)
        #expect(state.streamingTask == nil)
    }
}

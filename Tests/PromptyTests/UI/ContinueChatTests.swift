// ContinueChatTests.swift
// PromptyTests
//
// Tests for continue-chat conversation history management in AppState.

import Foundation
import Testing
@testable import Prompty

@MainActor
@Suite("Continue Chat")
struct ContinueChatTests {

    // MARK: - Conversation History Accumulation

    @Test("conversationHistory accumulates messages across turns")
    func test_conversationHistory_accumulatesMessages() {
        let state = AppState()

        let userMsg = AIMessage(role: .user, content: "Hello")
        let assistantMsg = AIMessage(
            role: .assistant, content: "Hi there"
        )

        state.appendToConversation(message: userMsg)
        state.appendToConversation(message: assistantMsg)

        #expect(state.conversationHistory.count == 2)
        #expect(state.conversationHistory[0].role == .user)
        #expect(state.conversationHistory[0].content == "Hello")
        #expect(state.conversationHistory[1].role == .assistant)
        #expect(state.conversationHistory[1].content == "Hi there")
    }

    // MARK: - Start Over

    @Test("startOver clears history and resets mode to promptPicker")
    func test_startOver_clearsHistoryAndResetsMode() {
        let state = AppState()

        // Set up state as if in a conversation
        state.panelMode = .continueChat
        state.streamingTokens = "some tokens"
        state.isStreaming = false
        state.followUpInput = "pending question"
        state.conversationHistory = [
            AIMessage(role: .user, content: "Hello"),
            AIMessage(role: .assistant, content: "Hi")
        ]

        state.startOver()

        #expect(state.conversationHistory.isEmpty)
        #expect(state.panelMode == .promptPicker)
        #expect(state.streamingTokens == "")
        #expect(state.followUpInput == "")
        #expect(state.isStreaming == false)
        #expect(state.isWaitingForFirstToken == false)
    }

    // MARK: - Follow-Up Appends to History

    @Test("follow-up appends user message to history")
    func test_followUp_appendsToHistory() {
        let state = AppState()

        // Simulate initial exchange
        state.appendToConversation(
            message: AIMessage(role: .user, content: "First question")
        )
        state.appendToConversation(
            message: AIMessage(
                role: .assistant, content: "First answer"
            )
        )

        // Simulate follow-up
        let followUp = AIMessage(
            role: .user, content: "Follow-up question"
        )
        state.appendToConversation(message: followUp)

        #expect(state.conversationHistory.count == 3)
        #expect(state.conversationHistory[2].role == .user)
        #expect(
            state.conversationHistory[2].content == "Follow-up question"
        )
    }

    // MARK: - AI Response Appends to History

    @Test("AI response appends assistant message to history")
    func test_aiResponse_appendsToHistory() {
        let state = AppState()

        // Simulate user question
        state.appendToConversation(
            message: AIMessage(role: .user, content: "What is Swift?")
        )

        // Simulate AI response
        let response = AIMessage(
            role: .assistant,
            content: "Swift is a programming language by Apple."
        )
        state.appendToConversation(message: response)

        #expect(state.conversationHistory.count == 2)
        #expect(state.conversationHistory[1].role == .assistant)
        #expect(
            state.conversationHistory[1].content
            == "Swift is a programming language by Apple."
        )
    }

    // MARK: - Multiple Turns

    @Test("multiple turns build correct conversation thread")
    func test_multipleTurns_buildsCorrectThread() {
        let state = AppState()

        let messages: [AIMessage] = [
            AIMessage(role: .user, content: "Turn 1 user"),
            AIMessage(role: .assistant, content: "Turn 1 assistant"),
            AIMessage(role: .user, content: "Turn 2 user"),
            AIMessage(role: .assistant, content: "Turn 2 assistant"),
            AIMessage(role: .user, content: "Turn 3 user"),
            AIMessage(role: .assistant, content: "Turn 3 assistant")
        ]

        for msg in messages {
            state.appendToConversation(message: msg)
        }

        #expect(state.conversationHistory.count == 6)
        #expect(state.conversationHistory == messages)
    }

    // MARK: - Start Over Preserves Captured Text

    @Test("startOver does not clear capturedText")
    func test_startOver_doesNotClearCapturedText() {
        let state = AppState()
        state.capturedText = "important text"
        state.panelMode = .continueChat
        state.conversationHistory = [
            AIMessage(role: .user, content: "test")
        ]

        state.startOver()

        // capturedText is preserved so user can pick a new prompt
        #expect(state.capturedText == "important text")
    }

    // MARK: - Reset Clears Follow-Up Input

    @Test("reset clears followUpInput")
    func test_reset_clearsFollowUpInput() {
        let state = AppState()
        state.followUpInput = "pending question"

        state.reset(capturedText: "new text")

        #expect(state.followUpInput == "")
    }

    // MARK: - History Passed in AIRequest

    @Test(
        "AIProviderManager receives history from conversation"
    )
    func test_aiRequest_containsConversationHistory() async throws {
        let mock = MockAIProvider()
        mock.stubbedTokens = ["response"]

        let manager = AIProviderManager(providers: [mock])
        manager.activeProviderID = "mock"

        let history = [
            AIMessage(role: .user, content: "Hello"),
            AIMessage(role: .assistant, content: "Hi")
        ]

        let request = AIRequest(
            systemPrompt: nil,
            userPrompt: "Follow-up",
            selectedText: "text",
            history: history
        )

        let stream = manager.stream(request: request)
        for try await _ in stream {}

        #expect(mock.lastReceivedRequest != nil)
        #expect(mock.lastReceivedRequest?.history.count == 2)
        #expect(mock.lastReceivedRequest?.history[0].role == .user)
        #expect(
            mock.lastReceivedRequest?.history[0].content == "Hello"
        )
        #expect(
            mock.lastReceivedRequest?.history[1].role == .assistant
        )
    }
}

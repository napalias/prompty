// AppState.swift
// AITextTool
//
// @Observable global state (single source of truth).
// All AppState mutations MUST happen on @MainActor.

import Foundation

/// Single source of truth for the entire application.
/// All properties are initialized to defaults with no side effects,
/// making AppState safe for SwiftUI previews.
@Observable
@MainActor
final class AppState {

    // MARK: - Text

    var capturedText: String = ""
    var selectedPrompt: Prompt?
    var customPromptInput: String = ""
    var capturedTextWasTruncated: Bool = false
    var capturedTextOriginalLength: Int = 0

    // MARK: - AI Response

    var streamingTokens: String = ""
    var isStreaming: Bool = false
    var isWaitingForFirstToken: Bool = false
    var streamingError: AppError?
    var lastResponseTokens: TokenUsage?
    private(set) var streamingTask: Task<Void, Never>?

    // MARK: - Panel

    var panelMode: PanelMode = .promptPicker
    var panelModeSessionRenderOverride: ResultRenderMode?
    var isVisible: Bool = false

    // MARK: - Conversation

    var conversationHistory: [AIMessage] = []
    var currentSession: ConversationSession?
    var followUpInput: String = ""

    // MARK: - Init

    /// Empty init with no side effects, safe for previews.
    init() {}

    // MARK: - Mutations

    func startStreaming(task: Task<Void, Never>) {
        streamingTask = task
        isStreaming = true
    }

    func cancelStreaming() {
        streamingTask?.cancel()
        streamingTask = nil
        isStreaming = false
    }

    /// Appends a message to the conversation history for multi-turn chat.
    func appendToConversation(message: AIMessage) {
        conversationHistory.append(message)
    }

    /// Clears conversation history and returns panel to promptPicker mode.
    func startOver() {
        conversationHistory = []
        streamingTokens = ""
        isStreaming = false
        isWaitingForFirstToken = false
        streamingError = nil
        streamingTask = nil
        lastResponseTokens = nil
        followUpInput = ""
        panelMode = .promptPicker
    }

    func reset(capturedText newText: String) {
        capturedText = newText
        capturedTextWasTruncated = false
        capturedTextOriginalLength = newText.count

        streamingTokens = ""
        isStreaming = false
        isWaitingForFirstToken = false
        streamingError = nil
        streamingTask = nil
        lastResponseTokens = nil

        panelMode = .promptPicker
        panelModeSessionRenderOverride = nil
        selectedPrompt = nil
        customPromptInput = ""
        followUpInput = ""

        conversationHistory = []
    }
}

// MARK: - TokenUsage

struct TokenUsage: Sendable, Equatable {
    let inputTokens: Int
    let outputTokens: Int
    let providerID: String

    var estimatedCostUSD: Double? {
        switch providerID {
        case "anthropic-api":
            return (Double(inputTokens) * 15 + Double(outputTokens) * 75) / 1_000_000
        case "openai":
            return (Double(inputTokens) * 2.5 + Double(outputTokens) * 10) / 1_000_000
        default:
            return nil
        }
    }

    var display: String {
        var parts = ["\(inputTokens + outputTokens) tokens"]
        if let cost = estimatedCostUSD, cost > 0.0001 {
            parts.append(String(format: "~$%.4f", cost))
        }
        return parts.joined(separator: " · ")
    }
}

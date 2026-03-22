// AppState.swift
// Prompty
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

    // MARK: - Dependencies

    private let sessionRepo: SessionHistoryRepositoryProtocol?

    // MARK: - Init

    /// Init with optional session repository for dependency injection.
    /// Pass nil (default) for previews; pass a real or mock repo for production/tests.
    init(sessionRepo: SessionHistoryRepositoryProtocol? = nil) {
        self.sessionRepo = sessionRepo
    }

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

    // MARK: - Session Lifecycle

    /// Creates a new conversation session when the hotkey fires on captured text.
    func startSession(capturedText: String, prompt: Prompt, providerID: String) {
        currentSession = ConversationSession(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            originalText: capturedText,
            providerID: providerID,
            promptTitle: prompt.title,
            messages: [],
            finalResult: nil
        )
    }

    /// Appends a message to the current session and updates metadata.
    func appendToSession(message: AIMessage) {
        currentSession?.messages.append(message)
        currentSession?.updatedAt = Date()
        if message.role == .assistant {
            currentSession?.finalResult = message.content
        }
    }

    /// Saves the current session to the repository and clears session state.
    func endSession() {
        guard let session = currentSession else { return }
        try? sessionRepo?.save(session)
        currentSession = nil
        conversationHistory = []
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

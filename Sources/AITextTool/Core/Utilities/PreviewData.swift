// PreviewData.swift
// AITextTool
//
// Static mock data for SwiftUI #Preview blocks.
// Used exclusively in previews, never in production code.

import Foundation

enum PreviewData {
    static let shortText = "The quick brown fox jumps over the lazy dog."

    static let longText = """
        Artificial intelligence is transforming how we interact with computers. \
        From natural language processing to computer vision, AI systems are \
        becoming increasingly capable of understanding and generating human content.
        """

    static let codeText = """
        func calculateFibonacci(_ n: Int) -> Int {
            if n <= 1 { return n }
            return calculateFibonacci(n - 1) + calculateFibonacci(n - 2)
        }
        """

    static let streamingTokens = "Here is the improved version of your text with better clarity and flow."

    static let conversation: [AIMessage] = [
        AIMessage(role: .user, content: "Fix the grammar in: \(shortText)"),
        AIMessage(role: .assistant, content: streamingTokens),
        AIMessage(role: .user, content: "Make it more formal"),
        AIMessage(role: .assistant, content: "Herewith is a more formal rendition.")
    ]

    static let sampleError: AppError = .apiKeyInvalid(providerID: "anthropic-api")

    @MainActor
    static func makeAppState(mode: PanelMode = .promptPicker) -> AppState {
        let state = AppState()
        state.capturedText = shortText
        state.panelMode = mode
        if mode == .streaming {
            state.streamingTokens = streamingTokens
            state.isStreaming = false
        }
        return state
    }
}

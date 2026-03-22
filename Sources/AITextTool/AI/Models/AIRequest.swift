// AIRequest.swift
// AITextTool

import Foundation

/// Encapsulates all data needed for an AI provider request.
struct AIRequest: Sendable {
    let systemPrompt: String?
    let userPrompt: String
    let selectedText: String
    let history: [AIMessage]
}

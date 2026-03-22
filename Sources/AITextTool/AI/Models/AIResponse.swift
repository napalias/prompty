// AIResponse.swift
// AITextTool

import Foundation

/// Represents a streaming token or final result from an AI provider.
struct AIResponse: Sendable {
    let token: String
    let isDone: Bool
}

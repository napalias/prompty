// AIMessage.swift
// AITextTool

import Foundation

/// A single message in a conversation with an AI provider.
struct AIMessage: Codable, Equatable, Sendable {
    enum Role: String, Codable, Sendable {
        case user
        case assistant
        case system
    }

    let role: Role
    let content: String
}

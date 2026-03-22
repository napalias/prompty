// ConversationSession.swift
// Prompty
//
// Model representing a single conversation session between user and AI.
// Will be migrated to SwiftData @Model in a later task (21B).

import Foundation

struct ConversationSession: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let createdAt: Date
    var updatedAt: Date
    let originalText: String
    let providerID: String
    let promptTitle: String
    var messages: [AIMessage]
    var finalResult: String?

    /// First 80 chars of originalText for display in history list.
    var summary: String {
        let prefix = String(originalText.prefix(80))
        return originalText.count > 80 ? prefix + "..." : prefix
    }
}

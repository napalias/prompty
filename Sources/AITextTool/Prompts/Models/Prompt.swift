// Prompt.swift
// AITextTool
//
// Complete Prompt model (21A final definition).

import Foundation

/// Value type representing a user or built-in prompt template.
struct Prompt: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var title: String
    var icon: String
    var template: String
    var resultMode: ResultMode
    var renderMode: ResultRenderMode
    var pasteMode: PasteMode
    var providerOverride: String?
    var systemPromptOverride: String?
    var isBuiltIn: Bool
    var isHidden: Bool
    var sortOrder: Int
    var lastUsedAt: Date?
}

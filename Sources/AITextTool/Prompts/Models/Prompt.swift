// Prompt.swift
// AITextTool
//
// Complete Prompt model (21A final definition).

import Foundation

/// Value type representing a user or built-in prompt template.
/// Contains `{{text}}` placeholder in template for selected text injection.
struct Prompt: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var title: String
    var icon: String              // SF Symbol name
    var template: String          // may contain {{text}} and/or {input}
    var resultMode: ResultMode
    var renderMode: ResultRenderMode
    var pasteMode: PasteMode
    var providerOverride: String?
    var systemPromptOverride: String?
    var isBuiltIn: Bool
    var isHidden: Bool
    var sortOrder: Int
    var lastUsedAt: Date?
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        icon: String,
        template: String,
        resultMode: ResultMode,
        renderMode: ResultRenderMode = .markdown,
        pasteMode: PasteMode = .plain,
        providerOverride: String? = nil,
        systemPromptOverride: String? = nil,
        isBuiltIn: Bool = false,
        isHidden: Bool = false,
        sortOrder: Int = 0,
        lastUsedAt: Date? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.template = template
        self.resultMode = resultMode
        self.renderMode = renderMode
        self.pasteMode = pasteMode
        self.providerOverride = providerOverride
        self.systemPromptOverride = systemPromptOverride
        self.isBuiltIn = isBuiltIn
        self.isHidden = isHidden
        self.sortOrder = sortOrder
        self.lastUsedAt = lastUsedAt
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

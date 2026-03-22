// PromptRepository.swift
// AITextTool
//
// JSON file-based prompt persistence.

import Foundation

final class PromptRepository: PromptRepositoryProtocol {
    func all() -> [Prompt] {
        // TODO: Load from JSON, filter hidden
        BuiltInPrompts.all
    }

    func allIncludingHidden() -> [Prompt] {
        // TODO: Load from JSON including hidden
        BuiltInPrompts.all
    }

    func add(_ prompt: Prompt) throws {
        // TODO: Validate and persist
    }

    func update(_ prompt: Prompt) throws {
        // TODO: Validate and persist
    }

    func delete(id: UUID) throws {
        // TODO: Implement delete (reject built-ins)
    }

    func hide(id: UUID) throws {
        // TODO: Mark prompt as hidden
    }

    func unhide(id: UUID) throws {
        // TODO: Restore hidden prompt
    }

    func reorder(_ ids: [UUID]) throws {
        // TODO: Apply new sort order
    }

    func recordUsage(id: UUID) throws {
        // TODO: Update lastUsedAt
    }
}

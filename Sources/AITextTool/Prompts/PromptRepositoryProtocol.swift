// PromptRepositoryProtocol.swift
// AITextTool

import Foundation

/// CRUD protocol for prompt persistence.
protocol PromptRepositoryProtocol: Sendable {
    /// Returns all non-hidden prompts sorted by sortOrder.
    func all() -> [Prompt]
    /// Returns all prompts including hidden ones.
    func allIncludingHidden() -> [Prompt]
    /// Returns a single prompt by ID, or nil if not found.
    func get(id: UUID) -> Prompt?
    /// Saves a prompt (inserts if new, updates if existing).
    func save(_ prompt: Prompt) throws
    /// Deletes a prompt by ID. Throws if the prompt is built-in.
    func delete(id: UUID) throws
    /// Hides a built-in prompt from the picker (copy-on-edit).
    func hide(id: UUID) throws
    /// Restores a hidden built-in prompt.
    func unhide(id: UUID) throws
    /// Reorders prompts by the given ID sequence.
    func reorder(ids: [UUID]) throws
    /// Searches prompts by title (case-insensitive).
    func search(query: String) -> [Prompt]
    /// Returns recently used prompts, most recent first.
    func recentlyUsed(limit: Int) -> [Prompt]
}

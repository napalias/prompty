// PromptRepositoryProtocol.swift
// AITextTool

import Foundation

/// CRUD protocol for prompt persistence.
protocol PromptRepositoryProtocol {
    /// Returns all non-hidden prompts.
    func all() -> [Prompt]
    /// Returns all prompts including hidden ones.
    func allIncludingHidden() -> [Prompt]
    /// Adds a new prompt.
    func add(_ prompt: Prompt) throws
    /// Updates an existing prompt.
    func update(_ prompt: Prompt) throws
    /// Deletes a prompt by ID. Throws if the prompt is built-in.
    func delete(id: UUID) throws
    /// Hides a built-in prompt from the picker (copy-on-edit).
    func hide(id: UUID) throws
    /// Restores a hidden built-in prompt.
    func unhide(id: UUID) throws
    /// Reorders prompts by the given ID sequence.
    func reorder(_ ids: [UUID]) throws
    /// Records that a prompt was just used (updates lastUsedAt).
    func recordUsage(id: UUID) throws
}

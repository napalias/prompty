// MockPromptRepository.swift
// AITextToolTests

import Foundation
@testable import AITextTool

final class MockPromptRepository: PromptRepositoryProtocol {
    var prompts: [Prompt] = BuiltInPrompts.all

    func all() -> [Prompt] {
        prompts.filter { !$0.isHidden }
    }

    func allIncludingHidden() -> [Prompt] {
        prompts
    }

    func add(_ prompt: Prompt) throws {
        prompts.append(prompt)
    }

    func update(_ prompt: Prompt) throws {
        guard let idx = prompts.firstIndex(where: { $0.id == prompt.id }) else { return }
        prompts[idx] = prompt
    }

    func delete(id: UUID) throws {
        prompts.removeAll { $0.id == id }
    }

    func hide(id: UUID) throws {
        guard let idx = prompts.firstIndex(where: { $0.id == id }) else { return }
        prompts[idx].isHidden = true
    }

    func unhide(id: UUID) throws {
        guard let idx = prompts.firstIndex(where: { $0.id == id }) else { return }
        prompts[idx].isHidden = false
    }

    func reorder(_ ids: [UUID]) throws {
        // Stub
    }

    func recordUsage(id: UUID) throws {
        guard let idx = prompts.firstIndex(where: { $0.id == id }) else { return }
        prompts[idx].lastUsedAt = Date()
    }
}

// MockPromptRepository.swift
// AITextToolTests

import Foundation
@testable import AITextTool

final class MockPromptRepository: PromptRepositoryProtocol, @unchecked Sendable {
    var prompts: [Prompt] = BuiltInPrompts.all
    var saveCalled = false
    var deleteCalled = false
    var hideCalled = false
    var unhideCalled = false

    func all() -> [Prompt] {
        prompts
            .filter { !$0.isHidden }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    func allIncludingHidden() -> [Prompt] {
        prompts.sorted { $0.sortOrder < $1.sortOrder }
    }

    func get(id: UUID) -> Prompt? {
        prompts.first { $0.id == id }
    }

    func save(_ prompt: Prompt) throws {
        saveCalled = true
        if let idx = prompts.firstIndex(where: { $0.id == prompt.id }) {
            prompts[idx] = prompt
        } else {
            prompts.append(prompt)
        }
    }

    func delete(id: UUID) throws {
        deleteCalled = true
        guard let idx = prompts.firstIndex(where: { $0.id == id }) else {
            throw PromptRepositoryError.promptNotFound(id: id)
        }
        if prompts[idx].isBuiltIn {
            throw PromptRepositoryError.cannotDeleteBuiltIn
        }
        prompts.remove(at: idx)
    }

    func hide(id: UUID) throws {
        hideCalled = true
        guard let idx = prompts.firstIndex(where: { $0.id == id }) else {
            throw PromptRepositoryError.promptNotFound(id: id)
        }
        prompts[idx].isHidden = true
    }

    func unhide(id: UUID) throws {
        unhideCalled = true
        guard let idx = prompts.firstIndex(where: { $0.id == id }) else {
            throw PromptRepositoryError.promptNotFound(id: id)
        }
        prompts[idx].isHidden = false
    }

    func reorder(ids: [UUID]) throws {
        for (order, promptID) in ids.enumerated() {
            if let idx = prompts.firstIndex(where: { $0.id == promptID }) {
                prompts[idx].sortOrder = order
            }
        }
    }

    func search(query: String) -> [Prompt] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return all() }
        return all().filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
        }
    }

    func recentlyUsed(limit: Int) -> [Prompt] {
        prompts
            .filter { !$0.isHidden && $0.lastUsedAt != nil }
            .sorted { ($0.lastUsedAt ?? .distantPast) > ($1.lastUsedAt ?? .distantPast) }
            .prefix(limit)
            .map { $0 }
    }
}

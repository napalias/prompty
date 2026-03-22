// PromptExportSchema.swift
// AITextTool
//
// Import/Export schema for prompt JSON files (18H)
// and preview helpers for PromptsSettingsView.

import SwiftUI
import UniformTypeIdentifiers

// MARK: - PromptExportSchema

struct PromptExportSchema: Codable {
    let version: Int
    let exportedAt: String
    let prompts: [ExportedPrompt]
}

// MARK: - ExportedPrompt

struct ExportedPrompt: Codable {
    let title: String
    let icon: String
    let template: String
    let resultMode: ResultMode
    let providerOverride: String?
}

// MARK: - PromptExportDocument

struct PromptExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let prompts: [Prompt]

    init(prompts: [Prompt]) {
        self.prompts = prompts
    }

    init(configuration: ReadConfiguration) throws {
        self.prompts = []
    }

    func fileWrapper(
        configuration: WriteConfiguration
    ) throws -> FileWrapper {
        let exported = prompts.map { prompt in
            ExportedPrompt(
                title: prompt.title,
                icon: prompt.icon,
                template: prompt.template,
                resultMode: prompt.resultMode,
                providerOverride: prompt.providerOverride
            )
        }
        let schema = PromptExportSchema(
            version: 1,
            exportedAt: ISO8601DateFormatter().string(from: Date()),
            prompts: exported
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(schema)
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Preview

#Preview("Prompts Settings") {
    PromptsSettingsView(promptRepo: PreviewPromptsRepo())
        .frame(width: 480, height: 500)
}

final class PreviewPromptsRepo: PromptRepositoryProtocol,
    @unchecked Sendable
{
    private var prompts: [Prompt] = BuiltInPrompts.all
    func all() -> [Prompt] { prompts.filter { !$0.isHidden } }
    func allIncludingHidden() -> [Prompt] { prompts }
    func get(id: UUID) -> Prompt? { prompts.first { $0.id == id } }
    func save(_ prompt: Prompt) throws {
        if let idx = prompts.firstIndex(where: { $0.id == prompt.id }) {
            prompts[idx] = prompt
        } else {
            prompts.append(prompt)
        }
    }
    func delete(id: UUID) throws {
        prompts.removeAll { $0.id == id }
    }
    func hide(id: UUID) throws {
        if let idx = prompts.firstIndex(where: { $0.id == id }) {
            prompts[idx].isHidden = true
        }
    }
    func unhide(id: UUID) throws {
        if let idx = prompts.firstIndex(where: { $0.id == id }) {
            prompts[idx].isHidden = false
        }
    }
    func reorder(ids: [UUID]) throws {}
    func search(query: String) -> [Prompt] { all() }
    func recentlyUsed(limit: Int) -> [Prompt] { [] }
}

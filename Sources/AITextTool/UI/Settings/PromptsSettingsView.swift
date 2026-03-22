// PromptsSettingsView.swift
// AITextTool
//
// CRUD for custom prompts with drag-to-reorder, import/export JSON.
// Built-in prompts shown but not deletable. Edit sheet for prompt fields.

import SwiftUI
import UniformTypeIdentifiers
import os

// MARK: - PromptsSettingsView

struct PromptsSettingsView: View {
    let promptRepo: PromptRepositoryProtocol

    @State private var allPrompts: [Prompt] = []
    @State private var editingPrompt: Prompt?
    @State private var isShowingEditor: Bool = false
    @State private var isCreatingNew: Bool = false
    @State private var promptToDelete: Prompt?
    @State private var isShowingDeleteAlert: Bool = false
    @State private var isShowingImporter: Bool = false
    @State private var isShowingExporter: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            promptList
            Divider()
            importExportBar
        }
        .onAppear { reload() }
        .sheet(isPresented: $isShowingEditor) {
            editorSheet
        }
        .alert(
            Strings.Settings.confirmDelete,
            isPresented: $isShowingDeleteAlert
        ) {
            Button(Strings.Settings.deletePrompt, role: .destructive) {
                performDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(Strings.Settings.confirmDeleteMessage)
        }
        .fileImporter(
            isPresented: $isShowingImporter,
            allowedContentTypes: [.json]
        ) { result in
            handleImport(result)
        }
        .fileExporter(
            isPresented: $isShowingExporter,
            document: promptExportDocument,
            contentType: .json,
            defaultFilename: "prompts-export.json"
        ) { _ in }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Text(Strings.Settings.prompts)
                .font(.headline)
            Spacer()
            Button {
                isCreatingNew = true
                editingPrompt = nil
                isShowingEditor = true
            } label: {
                Label(Strings.Settings.addPrompt, systemImage: "plus")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Prompt List

    private var promptList: some View {
        List {
            userPromptsSection
            builtInSection
            hiddenSection
        }
    }

    private var userPromptsSection: some View {
        Section(Strings.Settings.myPrompts) {
            ForEach(userPrompts) { prompt in
                promptRow(prompt, canDelete: true)
            }
            .onMove { from, to in
                moveUserPrompts(from: from, to: to)
            }
        }
    }

    private var builtInSection: some View {
        Section(Strings.Settings.builtInPrompts) {
            ForEach(visibleBuiltIns) { prompt in
                promptRow(prompt, canDelete: false)
            }
        }
    }

    @ViewBuilder
    private var hiddenSection: some View {
        let hidden = hiddenBuiltIns
        if !hidden.isEmpty {
            Section(Strings.Settings.hiddenPrompts) {
                ForEach(hidden) { prompt in
                    HStack {
                        Label(prompt.title, systemImage: prompt.icon)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button(Strings.Settings.restorePrompt) {
                            restorePrompt(prompt)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
    }

    // MARK: - Row

    private func promptRow(
        _ prompt: Prompt,
        canDelete: Bool
    ) -> some View {
        HStack {
            Label(prompt.title, systemImage: prompt.icon)
            Spacer()
            Button(Strings.Settings.editPrompt) {
                editingPrompt = prompt
                isCreatingNew = false
                isShowingEditor = true
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            if canDelete {
                Button(Strings.Settings.deletePrompt, role: .destructive) {
                    promptToDelete = prompt
                    isShowingDeleteAlert = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    // MARK: - Editor Sheet

    private var editorSheet: some View {
        PromptEditorSheet(
            prompt: editingPrompt,
            isNew: isCreatingNew,
            onSave: { updatedPrompt in
                savePrompt(updatedPrompt)
                isShowingEditor = false
            },
            onCancel: { isShowingEditor = false }
        )
        .frame(minWidth: 420, minHeight: 400)
    }

    // MARK: - Import / Export

    private var importExportBar: some View {
        HStack {
            Button(Strings.Settings.importPrompts) {
                isShowingImporter = true
            }
            Button(Strings.Settings.exportPrompts) {
                isShowingExporter = true
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Computed

    private var userPrompts: [Prompt] {
        allPrompts
            .filter { !$0.isBuiltIn && !$0.isHidden }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private var visibleBuiltIns: [Prompt] {
        allPrompts
            .filter { $0.isBuiltIn && !$0.isHidden }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private var hiddenBuiltIns: [Prompt] {
        allPrompts.filter { $0.isBuiltIn && $0.isHidden }
    }

    private var promptExportDocument: PromptExportDocument {
        PromptExportDocument(prompts: allPrompts.filter { !$0.isHidden })
    }

    // MARK: - Actions

    private func reload() {
        allPrompts = promptRepo.allIncludingHidden()
    }

    private func savePrompt(_ prompt: Prompt) {
        do {
            try promptRepo.save(prompt)
            reload()
        } catch {
            Logger.settings.error(
                "Failed to save prompt: \(error.localizedDescription)"
            )
        }
    }

    private func performDelete() {
        guard let prompt = promptToDelete else { return }
        do {
            try promptRepo.delete(id: prompt.id)
            reload()
        } catch {
            Logger.settings.error(
                "Failed to delete prompt: \(error.localizedDescription)"
            )
        }
        promptToDelete = nil
    }

    private func restorePrompt(_ prompt: Prompt) {
        do {
            try promptRepo.unhide(id: prompt.id)
            reload()
        } catch {
            Logger.settings.error(
                "Failed to restore prompt: \(error.localizedDescription)"
            )
        }
    }

    private func moveUserPrompts(
        from source: IndexSet,
        to destination: Int
    ) {
        var ordered = userPrompts
        ordered.move(fromOffsets: source, toOffset: destination)
        let ids = ordered.map(\.id)
        try? promptRepo.reorder(ids: ids)
        reload()
    }

    private func handleImport(_ result: Result<URL, Error>) {
        guard case let .success(url) = result else { return }
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let data = try Data(contentsOf: url)
            let export = try JSONDecoder().decode(
                PromptExportSchema.self,
                from: data
            )
            let existing = promptRepo.all()
            for imported in export.prompts {
                // Skip duplicates with same title and template (18H)
                let isDuplicate = existing.contains {
                    $0.title == imported.title
                        && $0.template == imported.template
                }
                if !isDuplicate {
                    let prompt = Prompt(
                        title: imported.title,
                        icon: imported.icon,
                        template: imported.template,
                        resultMode: imported.resultMode
                    )
                    try promptRepo.save(prompt)
                }
            }
            reload()
        } catch {
            Logger.settings.error(
                "Import failed: \(error.localizedDescription)"
            )
        }
    }
}

// MARK: - PromptEditorSheet

private struct PromptEditorSheet: View {
    let prompt: Prompt?
    let isNew: Bool
    let onSave: (Prompt) -> Void
    let onCancel: () -> Void

    @State private var title: String = ""
    @State private var icon: String = "sparkles"
    @State private var template: String = ""
    @State private var resultMode: ResultMode = .replace
    @State private var renderMode: ResultRenderMode = .markdown
    @State private var pasteMode: PasteMode = .plain

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
            && !template.trimmingCharacters(in: .whitespaces).isEmpty
            && title.count <= 50
            && template.count <= 2000
    }

    var body: some View {
        VStack(spacing: 0) {
            editorHeader
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    titleAndIconRow
                    templateSection
                    resultModeSection
                    renderModeSection
                    pasteModeSection
                }
                .padding()
            }
        }
        .onAppear { loadFromPrompt() }
    }

    // MARK: - Header

    private var editorHeader: some View {
        HStack {
            Button("Cancel", action: onCancel)
                .keyboardShortcut(.escape, modifiers: [])
            Spacer()
            Text(
                isNew
                    ? Strings.Settings.addPrompt
                    : Strings.Settings.editPrompt
            )
            .font(.headline)
            Spacer()
            Button(isNew ? "Create" : "Save") { save() }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(!isValid)
        }
        .padding()
    }

    // MARK: - Fields

    private var titleAndIconRow: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(Strings.Settings.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField(Strings.Settings.title, text: $title)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Strings.Settings.template)
                .font(.caption)
                .foregroundStyle(.secondary)

            TextEditor(text: $template)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 100, maxHeight: 180)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.separator)
                )

            if !template.contains("{text}") && !template.isEmpty {
                Label(
                    "No {text} placeholder -- selected text will be appended",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.caption)
                .foregroundStyle(.orange)
            }
        }
    }

    private var resultModeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Strings.Settings.resultMode)
                .font(.caption)
                .foregroundStyle(.secondary)
            Picker(
                Strings.Settings.resultMode,
                selection: $resultMode
            ) {
                Text("Replace").tag(ResultMode.replace)
                Text("Copy").tag(ResultMode.copy)
                Text("Diff").tag(ResultMode.diff)
                Text("Chat").tag(ResultMode.continueChat)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    private var renderModeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Strings.Settings.renderMode)
                .font(.caption)
                .foregroundStyle(.secondary)
            Picker(
                Strings.Settings.renderMode,
                selection: $renderMode
            ) {
                Text("Markdown").tag(ResultRenderMode.markdown)
                Text("Plain").tag(ResultRenderMode.plain)
                Text("Code").tag(ResultRenderMode.code)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    private var pasteModeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Strings.Settings.pasteMode)
                .font(.caption)
                .foregroundStyle(.secondary)
            Picker(
                Strings.Settings.pasteMode,
                selection: $pasteMode
            ) {
                Text("Plain text").tag(PasteMode.plain)
                Text("Rich text").tag(PasteMode.rich)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    // MARK: - Private

    private func loadFromPrompt() {
        guard let prompt else { return }
        title = prompt.title
        icon = prompt.icon
        template = prompt.template
        resultMode = prompt.resultMode
        renderMode = prompt.renderMode
        pasteMode = prompt.pasteMode
    }

    private func save() {
        guard isValid else { return }

        if let existing = prompt {
            if existing.isBuiltIn {
                // Copy-on-edit: create personal copy (21A)
                let copy = Prompt(
                    title: title,
                    icon: icon,
                    template: template,
                    resultMode: resultMode,
                    renderMode: renderMode,
                    pasteMode: pasteMode,
                    isBuiltIn: false,
                    sortOrder: existing.sortOrder
                )
                onSave(copy)
            } else {
                var updated = existing
                updated.title = title
                updated.icon = icon
                updated.template = template
                updated.resultMode = resultMode
                updated.renderMode = renderMode
                updated.pasteMode = pasteMode
                onSave(updated)
            }
        } else {
            let newPrompt = Prompt(
                title: title,
                icon: icon,
                template: template,
                resultMode: resultMode,
                renderMode: renderMode,
                pasteMode: pasteMode,
                sortOrder: Int.max
            )
            onSave(newPrompt)
        }
    }
}

// MARK: - Import/Export Schema (18H)

struct PromptExportSchema: Codable {
    let version: Int
    let exportedAt: String
    let prompts: [ExportedPrompt]
}

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

#Preview {
    PromptsSettingsView(promptRepo: PreviewPromptsRepo())
        .frame(width: 480, height: 500)
}

private final class PreviewPromptsRepo: PromptRepositoryProtocol,
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

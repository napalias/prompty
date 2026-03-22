// PromptsSettingsView.swift
// Prompty
//
// CRUD for custom prompts with drag-to-reorder, import/export JSON.
// Built-in prompts shown but not deletable. Edit sheet for prompt fields.

import SwiftUI
import UniformTypeIdentifiers
import os

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
        .sheet(isPresented: $isShowingEditor) { editorSheet }
        .alert(
            Strings.Settings.confirmDelete,
            isPresented: $isShowingDeleteAlert
        ) {
            Button(Strings.Settings.deletePrompt, role: .destructive) { performDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(Strings.Settings.confirmDeleteMessage)
        }
        .fileImporter(
            isPresented: $isShowingImporter,
            allowedContentTypes: [.json]
        ) { handleImport($0) }
        .fileExporter(
            isPresented: $isShowingExporter,
            document: promptExportDocument,
            contentType: .json,
            defaultFilename: "prompts-export.json"
        ) { _ in }
    }

    // MARK: - Subviews

    private var headerBar: some View {
        HStack {
            Text(Strings.Settings.prompts).font(.headline)
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
            .onMove { from, to in moveUserPrompts(from: from, to: to) }
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
                        Button(Strings.Settings.restorePrompt) { restorePrompt(prompt) }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                }
            }
        }
    }

    private func promptRow(_ prompt: Prompt, canDelete: Bool) -> some View {
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

    private var editorSheet: some View {
        PromptEditorSheet(
            prompt: editingPrompt,
            isNew: isCreatingNew,
            onSave: { savePrompt($0); isShowingEditor = false },
            onCancel: { isShowingEditor = false }
        )
        .frame(minWidth: 420, minHeight: 400)
    }

    private var importExportBar: some View {
        HStack {
            Button(Strings.Settings.importPrompts) { isShowingImporter = true }
            Button(Strings.Settings.exportPrompts) { isShowingExporter = true }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Computed

    private var userPrompts: [Prompt] {
        allPrompts.filter { !$0.isBuiltIn && !$0.isHidden }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private var visibleBuiltIns: [Prompt] {
        allPrompts.filter { $0.isBuiltIn && !$0.isHidden }
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
            Logger.settings.error("Failed to save prompt: \(error.localizedDescription)")
        }
    }

    private func performDelete() {
        guard let prompt = promptToDelete else { return }
        do {
            try promptRepo.delete(id: prompt.id)
            reload()
        } catch {
            Logger.settings.error("Failed to delete prompt: \(error.localizedDescription)")
        }
        promptToDelete = nil
    }

    private func restorePrompt(_ prompt: Prompt) {
        do {
            try promptRepo.unhide(id: prompt.id)
            reload()
        } catch {
            Logger.settings.error("Failed to restore prompt: \(error.localizedDescription)")
        }
    }

    private func moveUserPrompts(from source: IndexSet, to destination: Int) {
        var ordered = userPrompts
        ordered.move(fromOffsets: source, toOffset: destination)
        try? promptRepo.reorder(ids: ordered.map(\.id))
        reload()
    }

    private func handleImport(_ result: Result<URL, Error>) {
        guard case let .success(url) = result else { return }
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        do {
            let data = try Data(contentsOf: url)
            let export = try JSONDecoder().decode(PromptExportSchema.self, from: data)
            let existing = promptRepo.all()
            for imported in export.prompts where !existing.contains(where: {
                $0.title == imported.title && $0.template == imported.template
            }) {
                try promptRepo.save(Prompt(
                    title: imported.title,
                    icon: imported.icon,
                    template: imported.template,
                    resultMode: imported.resultMode
                ))
            }
            reload()
        } catch {
            Logger.settings.error("Import failed: \(error.localizedDescription)")
        }
    }
}

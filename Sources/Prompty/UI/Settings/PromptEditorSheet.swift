// PromptEditorSheet.swift
// Prompty
//
// Sheet view for creating and editing prompts.

import SwiftUI

// MARK: - PromptEditorSheet

struct PromptEditorSheet: View {
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

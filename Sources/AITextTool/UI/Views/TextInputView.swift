// TextInputView.swift
// AITextTool
//
// Free-text prompt input with submit button.
// Used for custom/ad-hoc prompts where the user types their own instruction.

import SwiftUI

struct TextInputView: View {
    @Environment(AppState.self) private var state

    @State private var inputText: String = ""

    var body: some View {
        VStack(spacing: 12) {
            header

            TextEditor(text: $inputText)
                .font(.body)
                .frame(minHeight: 60, maxHeight: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.separator)
                )
                .accessibilityLabel(Strings.Panel.customPromptInputLabel)

            HStack {
                Button(Strings.ActionBar.dismiss) {
                    state.panelMode = .promptPicker
                }
                .keyboardShortcut(.escape, modifiers: [])

                Spacer()

                Button(Strings.Panel.send) {
                    submitInput()
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: {
                state.panelMode = .promptPicker
            }) {
                Label(Strings.Panel.back, systemImage: "chevron.left")
            }
            .buttonStyle(.plain)

            Spacer()

            Text(Strings.Panel.customPrompt)
                .font(.headline)

            Spacer()
        }
    }

    // MARK: - Actions

    private func submitInput() {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        state.customPromptInput = trimmed
        state.panelMode = .streaming
        state.isWaitingForFirstToken = true
    }
}

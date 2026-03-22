// EditBeforeReplaceView.swift
// AITextTool
//
// TextEditor showing AI result, user can edit before confirming replace (20I).
// Confirm replaces in source app; cancel returns to streaming result.

import SwiftUI

struct EditBeforeReplaceView: View {
    @Environment(AppState.self) var state
    let onConfirm: (String) -> Void
    let onCancel: () -> Void

    @State private var editedText: String = ""

    var body: some View {
        VStack(spacing: 8) {
            Label(
                Strings.EditBeforeReplace.title,
                systemImage: "pencil"
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            TextEditor(text: $editedText)
                .font(.body)
                .frame(minHeight: 80, maxHeight: 200)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.separator)
                )

            HStack {
                Button(Strings.ActionBar.dismiss, action: onCancel)
                    .keyboardShortcut(.escape, modifiers: [])
                Spacer()
                Button(Strings.ActionBar.replace) {
                    onConfirm(editedText)
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .onAppear { editedText = state.streamingTokens }
    }
}

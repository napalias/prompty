// MainPanelView.swift
// AITextTool
//
// Root view that routes to sub-views based on AppState.panelMode.
// Handles all keyboard events for result actions:
//   Enter -> replace, Cmd+Enter -> copy, D -> diff, E -> edit, Escape -> dismiss.

import SwiftUI

struct MainPanelView: View {
    @Environment(AppState.self) var state
    var textReplaceService: TextReplaceServiceProtocol?
    var onDismiss: (() -> Void)?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)

            panelContent
        }
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Panel Content

    @ViewBuilder
    private var panelContent: some View {
        switch state.panelMode {
        case .promptPicker:
            PromptPickerView()
        case .customInput:
            TextInputView()
        case .streaming:
            StreamingResultView()
        case .diff:
            DiffView(
                onAccept: handleReplace,
                onReject: handleDismiss,
                onEdit: handleEdit
            )
        case .continueChat:
            ContinueChatView()
        case .editBeforeReplace:
            EditBeforeReplaceView(
                onConfirm: handleEditConfirm,
                onCancel: handleEditCancel
            )
        case .error:
            ErrorView()
        case .noProviderConfigured:
            ErrorView()
        case .promptEditor:
            ErrorView()
        }
    }

    // MARK: - Key Actions

    private func handleReplace() {
        guard let service = textReplaceService else { return }
        let text = state.streamingTokens
        let pasteMode = state.selectedPrompt?.pasteMode ?? .plain
        Task { @MainActor in
            do {
                try await service.replace(
                    with: text,
                    in: nil,
                    pasteMode: pasteMode
                )
            } catch {
                service.copyToClipboard(text)
            }
            handleDismiss()
        }
    }

    private func handleCopy() {
        textReplaceService?.copyToClipboard(state.streamingTokens)
        handleDismiss()
    }

    private func handleDiff() {
        guard !state.isStreaming else { return }
        state.panelMode = .diff
    }

    private func handleEdit() {
        guard !state.isStreaming else { return }
        state.panelMode = .editBeforeReplace
    }

    private func handleDismiss() {
        onDismiss?()
    }

    private func handleEditConfirm(_ text: String) {
        guard let service = textReplaceService else { return }
        let pasteMode = state.selectedPrompt?.pasteMode ?? .plain
        Task { @MainActor in
            do {
                try await service.replace(
                    with: text,
                    in: nil,
                    pasteMode: pasteMode
                )
            } catch {
                service.copyToClipboard(text)
            }
            handleDismiss()
        }
    }

    private func handleEditCancel() {
        state.panelMode = .streaming
    }
}

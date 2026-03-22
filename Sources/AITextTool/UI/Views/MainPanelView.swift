// MainPanelView.swift
// AITextTool
//
// Root SwiftUI view inside the floating panel.
// Routes to sub-views based on AppState.panelMode (21K definitive enum).
// Handles keyboard events for result actions.
// Uses .regularMaterial for system appearance adaptation (20T).

import SwiftUI

struct MainPanelView: View {
    @Environment(AppState.self) private var state
    var textReplaceService: TextReplaceServiceProtocol?
    var onDismiss: (() -> Void)?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)

            panelContent
                .padding(12)
        }
        .frame(width: PanelSizeConstraints.width)
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Strings.Accessibility.panelLabel)
    }

    // MARK: - Content Router

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
            noProviderView
        case .promptEditor:
            Text(Strings.Panel.thinking)
        }
    }

    // MARK: - No Provider Configured (21E)

    private var noProviderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "gearshape")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text(Strings.Errors.providerNotConfigured)
                .font(.headline)

            Text(Strings.Panel.noProviderDetail)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button(Strings.ActionBar.dismiss) {
                    state.panelMode = .promptPicker
                }
                Button(Strings.MenuBar.settings) {
                    NSApp.sendAction(
                        Selector(("showSettingsWindow:")),
                        to: nil,
                        from: nil
                    )
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    // MARK: - Key Actions

    private func handleReplace() {
        guard let service = textReplaceService else { return }
        let text = state.streamingTokens
        let pasteMode = state.selectedPrompt?.pasteMode ?? .plain
        Task { @MainActor in
            do {
                try await service.replace(with: text, in: nil, pasteMode: pasteMode)
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
                try await service.replace(with: text, in: nil, pasteMode: pasteMode)
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

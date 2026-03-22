// StreamingResultView.swift
// AITextTool
//
// Displays live streaming tokens with a blinking cursor while active.
// ActionBarView pinned at bottom shows keyboard shortcuts.
// Scrollable if content exceeds panel height.

import SwiftUI

struct StreamingResultView: View {
    @Environment(AppState.self) var state

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                resultContent
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .frame(maxHeight: 300)

            Divider()

            ActionBarView(
                resultMode: state.selectedPrompt?.resultMode ?? .copy,
                isStreaming: state.isStreaming,
                tokenUsage: state.lastResponseTokens
            )
        }
    }

    // MARK: - Result Content

    @ViewBuilder
    private var resultContent: some View {
        if state.isWaitingForFirstToken {
            loadingSkeleton
        } else {
            streamedText
        }
    }

    private var streamedText: some View {
        let renderMode = effectiveRenderMode

        return Group {
            switch renderMode {
            case .plain:
                Text(state.streamingTokens)
                    .font(.body)
                    .textSelection(.enabled)
            case .markdown:
                Text(LocalizedStringKey(state.streamingTokens))
                    .font(.body)
                    .textSelection(.enabled)
            case .code:
                Text(state.streamingTokens)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
    }

    private var effectiveRenderMode: ResultRenderMode {
        if let override = state.panelModeSessionRenderOverride {
            return override
        }
        return state.selectedPrompt?.renderMode ?? .markdown
    }

    // MARK: - Loading Skeleton

    private var loadingSkeleton: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(0..<3, id: \.self) { idx in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(
                        maxWidth: idx == 2 ? 120 : .infinity,
                        maxHeight: 14
                    )
            }
            Text(Strings.Panel.thinking)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

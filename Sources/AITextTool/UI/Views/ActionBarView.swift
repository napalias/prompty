// ActionBarView.swift
// AITextTool
//
// Keyboard hints bar at bottom of streaming result and chat views.
// Displays available actions and their keyboard shortcuts.
// Keys fire immediately via onKeyPress handlers in MainPanelView.

import SwiftUI

struct ActionBarView: View {
    let resultMode: ResultMode
    let isStreaming: Bool
    let tokenUsage: TokenUsage?

    var body: some View {
        HStack(spacing: 12) {
            if resultMode == .replace || resultMode == .diff {
                hintLabel(key: "\u{21A9}", label: Strings.ActionBar.replace)
            }
            hintLabel(key: "\u{2318}\u{21A9}", label: Strings.ActionBar.copy)
            if !isStreaming {
                hintLabel(key: "D", label: Strings.ActionBar.diff)
                hintLabel(key: "E", label: Strings.ActionBar.edit)
            }
            hintLabel(key: "Esc", label: Strings.ActionBar.dismiss)

            Spacer()

            if let usage = tokenUsage {
                Text(usage.display)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    // MARK: - Hint Label

    private func hintLabel(key: String, label: String) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.caption2.monospaced())
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.quaternary)
                )
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// DiffView.swift
// AITextTool
//
// Side-by-side display of original vs revised text with color coding.
// Red highlight for deleted words, green for inserted words.
// Accept/Reject/Edit buttons at bottom per spec 09_10_11.

import SwiftUI

struct DiffView: View {
    @Environment(AppState.self) var state
    let onAccept: () -> Void
    let onReject: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            diffContent
            Divider()
            buttonBar
        }
    }

    // MARK: - Diff Content

    private var diffContent: some View {
        let changes = DiffCalculator.diff(
            original: state.capturedText,
            revised: state.streamingTokens
        )
        return ScrollView {
            HStack(alignment: .top, spacing: 16) {
                originalColumn(changes: changes)
                Divider()
                revisedColumn(changes: changes)
            }
            .padding(12)
        }
        .frame(maxHeight: 300)
    }

    private func originalColumn(
        changes: [DiffCalculator.Change]
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Strings.Diff.original)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(buildOriginalAttributed(from: changes))
                .font(.body)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }

    private func revisedColumn(
        changes: [DiffCalculator.Change]
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Strings.Diff.revised)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(buildRevisedAttributed(from: changes))
                .font(.body)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Attributed String Builders

    /// Builds the original side: equal tokens as-is, deleted tokens
    /// highlighted with red background. Inserts are omitted.
    private func buildOriginalAttributed(
        from changes: [DiffCalculator.Change]
    ) -> AttributedString {
        var result = AttributedString()
        for change in changes {
            switch change {
            case .equal(let str):
                result.append(AttributedString(str))
            case .delete(let str):
                var attr = AttributedString(str)
                attr.backgroundColor = .red.opacity(0.3)
                attr.foregroundColor = .primary
                result.append(attr)
            case .insert:
                break
            }
        }
        return result
    }

    /// Builds the revised side: equal tokens as-is, inserted tokens
    /// highlighted with green background. Deletes are omitted.
    private func buildRevisedAttributed(
        from changes: [DiffCalculator.Change]
    ) -> AttributedString {
        var result = AttributedString()
        for change in changes {
            switch change {
            case .equal(let str):
                result.append(AttributedString(str))
            case .insert(let str):
                var attr = AttributedString(str)
                attr.backgroundColor = .green.opacity(0.3)
                attr.foregroundColor = .primary
                result.append(attr)
            case .delete:
                break
            }
        }
        return result
    }

    // MARK: - Button Bar

    private var buttonBar: some View {
        HStack(spacing: 12) {
            Button(Strings.ActionBar.reject, action: onReject)
                .keyboardShortcut(.escape, modifiers: [])
            Spacer()
            Button(Strings.ActionBar.edit, action: onEdit)
            Button(Strings.ActionBar.accept, action: onAccept)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: [])
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

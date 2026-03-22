// PromptPickerView.swift
// AITextTool
//
// Scrollable list of prompts with search filtering and keyboard navigation.
// Shows icon + title. Selecting a prompt triggers AI streaming.
// Empty state when search yields no results.
// Warning banners for long text per 16C.

import SwiftUI

struct PromptPickerView: View {
    @Environment(AppState.self) private var state

    @State private var searchText: String = ""
    @State private var selectedIndex: Int = 0

    // MARK: - Filtered Prompts

    /// Stub prompt list from BuiltInPrompts for now;
    /// will be replaced by PromptRepository injection in integration.
    private var allPrompts: [Prompt] {
        BuiltInPrompts.all.filter { !$0.isHidden }
    }

    private var filteredPrompts: [Prompt] {
        if searchText.isEmpty {
            return allPrompts
        }
        return allPrompts.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            searchField
            truncationBanner
            promptList
        }
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(Strings.Panel.searchPrompts, text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Truncation Banner (16C)

    @ViewBuilder
    private var truncationBanner: some View {
        if state.capturedTextOriginalLength > TextCaptureService.hardLimit {
            Label(
                "Text was truncated to \(TextCaptureService.hardLimit) chars",
                systemImage: "scissors"
            )
            .foregroundStyle(.orange)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.bottom, 4)
        } else if state.capturedTextOriginalLength > TextCaptureService.softLimit {
            Label(
                "\(state.capturedTextOriginalLength) chars selected",
                systemImage: "exclamationmark.triangle"
            )
            .foregroundStyle(.yellow)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.bottom, 4)
        }
    }

    // MARK: - Prompt List

    private var promptList: some View {
        Group {
            if filteredPrompts.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(
                            Array(filteredPrompts.enumerated()),
                            id: \.element.id
                        ) { index, prompt in
                            promptRow(prompt, index: index)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Prompt Row

    private func promptRow(
        _ prompt: Prompt,
        index: Int
    ) -> some View {
        Button(action: {
            selectPrompt(prompt)
        }) {
            HStack(spacing: 10) {
                Image(systemName: prompt.icon)
                    .frame(width: 20, height: 20)
                    .foregroundStyle(.secondary)
                Text(prompt.title)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                index == selectedIndex
                    ? Color.accentColor.opacity(0.15)
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(prompt.title)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(Strings.Panel.noPromptsMatch)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Actions

    private func selectPrompt(_ prompt: Prompt) {
        state.selectedPrompt = prompt
        if prompt.title == "Custom" {
            state.panelMode = .customInput
        } else {
            state.panelMode = .streaming
            state.isWaitingForFirstToken = true
        }
    }
}

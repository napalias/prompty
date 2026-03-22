// PromptPickerView.swift
// AITextTool
//
// Scrollable prompt list with search field, keyboard navigation
// (up/down arrows + Enter), recently used section, and empty state.
// Warning banners for long text per 16C.

import SwiftUI

struct PromptPickerView: View {
    @Environment(AppState.self) private var state

    var prompts: [Prompt] = BuiltInPrompts.all.filter { !$0.isHidden }
    var recentPrompts: [Prompt] = []
    var onSelect: ((Prompt) -> Void)?

    // MARK: - State

    @State private var searchText: String = ""
    @State private var selectedIndex: Int = 0
    @FocusState private var isSearchFocused: Bool

    // MARK: - Computed

    private var filteredPrompts: [Prompt] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return prompts }
        return prompts.filter {
            $0.title.localizedCaseInsensitiveContains(query)
        }
    }

    private var filteredRecents: [Prompt] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return recentPrompts }
        return recentPrompts.filter {
            $0.title.localizedCaseInsensitiveContains(query)
        }
    }

    private var allVisiblePrompts: [Prompt] {
        var result: [Prompt] = []
        let recents = filteredRecents
        result.append(contentsOf: recents)
        let remaining = filteredPrompts.filter { prompt in
            !recents.contains { $0.id == prompt.id }
        }
        result.append(contentsOf: remaining)
        return result
    }

    private var hasResults: Bool {
        !allVisiblePrompts.isEmpty
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            searchField
            truncationBanner
            Divider()

            if hasResults {
                promptList
            } else {
                emptyState
            }
        }
        .onKeyPress(.upArrow) { moveSelection(by: -1) }
        .onKeyPress(.downArrow) { moveSelection(by: 1) }
        .onKeyPress(.return) { confirmSelection() }
        .onChange(of: searchText) { _, _ in
            selectedIndex = 0
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Strings.Accessibility.promptList)
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField(
                Strings.PromptPicker.searchPlaceholder,
                text: $searchText
            )
            .textFieldStyle(.plain)
            .focused($isSearchFocused)
            .accessibilityLabel(Strings.Accessibility.searchField)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Strings.Accessibility.clearSearch)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .onAppear {
            isSearchFocused = true
        }
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
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    recentSection
                    allPromptsSection
                }
            }
            .onChange(of: selectedIndex) { _, newIndex in
                let visible = allVisiblePrompts
                guard newIndex >= 0, newIndex < visible.count else { return }
                withAnimation {
                    proxy.scrollTo(visible[newIndex].id, anchor: .center)
                }
            }
        }
    }

    // MARK: - Recent Section

    @ViewBuilder
    private var recentSection: some View {
        let recents = filteredRecents
        if !recents.isEmpty {
            sectionHeader(Strings.PromptPicker.recentlyUsed)
            ForEach(Array(recents.enumerated()), id: \.element.id) { offset, prompt in
                promptRow(prompt, isSelected: selectedIndex == offset)
                    .id(prompt.id)
                    .onTapGesture { selectPrompt(prompt) }
            }
        }
    }

    // MARK: - All Prompts Section

    @ViewBuilder
    private var allPromptsSection: some View {
        let recents = filteredRecents
        let remaining = filteredPrompts.filter { prompt in
            !recents.contains { $0.id == prompt.id }
        }

        if !remaining.isEmpty {
            sectionHeader(Strings.PromptPicker.allPrompts)
            ForEach(Array(remaining.enumerated()), id: \.element.id) { offset, prompt in
                let globalIndex = recents.count + offset
                promptRow(prompt, isSelected: selectedIndex == globalIndex)
                    .id(prompt.id)
                    .onTapGesture { selectPrompt(prompt) }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(Strings.PromptPicker.noResults)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(Strings.PromptPicker.noResultsDetail)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.PromptPicker.noResults)
    }

    // MARK: - Subviews

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .accessibilityAddTraits(.isHeader)
    }

    private func promptRow(_ prompt: Prompt, isSelected: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: prompt.icon)
                .frame(width: 20, height: 20)
                .foregroundStyle(isSelected ? .white : .primary)
                .accessibilityHidden(true)

            Text(prompt.title)
                .font(.body)
                .foregroundStyle(isSelected ? .white : .primary)
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            isSelected ? Color.accentColor : Color.clear,
            in: RoundedRectangle(cornerRadius: 6)
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(prompt.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Actions

    private func moveSelection(by delta: Int) -> KeyPress.Result {
        let count = allVisiblePrompts.count
        guard count > 0 else { return .handled }
        let next = selectedIndex + delta
        selectedIndex = max(0, min(count - 1, next))
        return .handled
    }

    private func confirmSelection() -> KeyPress.Result {
        let visible = allVisiblePrompts
        guard selectedIndex >= 0, selectedIndex < visible.count else { return .handled }
        selectPrompt(visible[selectedIndex])
        return .handled
    }

    private func selectPrompt(_ prompt: Prompt) {
        state.selectedPrompt = prompt
        if let onSelect {
            onSelect(prompt)
        } else {
            state.panelMode = .streaming
            state.isWaitingForFirstToken = true
        }
    }
}

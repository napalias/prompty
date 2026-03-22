// SettingsView.swift
// Prompty
//
// Tab container for settings with 4 tabs: General, Providers, Prompts, Logs.
// Keyboard shortcut Cmd+, opens this view (20Q).

import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {
    let settingsRepo: SettingsRepositoryProtocol
    let keychainService: KeychainServiceProtocol
    let promptRepo: PromptRepositoryProtocol

    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView(settingsRepo: settingsRepo)
                .tabItem {
                    Label(Strings.Settings.general, systemImage: "gear")
                }
                .tag(SettingsTab.general)

            ProvidersSettingsView(
                settingsRepo: settingsRepo,
                keychainService: keychainService
            )
            .tabItem {
                Label(Strings.Settings.providers, systemImage: "cloud")
            }
            .tag(SettingsTab.providers)

            PromptsSettingsView(promptRepo: promptRepo)
                .tabItem {
                    Label(
                        Strings.Settings.prompts,
                        systemImage: "text.bubble"
                    )
                }
                .tag(SettingsTab.prompts)

            LogsSettingsView(crashReporter: .shared)
                .tabItem {
                    Label(Strings.Logs.logs, systemImage: "doc.text")
                }
                .tag(SettingsTab.logs)
        }
        .frame(minWidth: 500, minHeight: 400)
        .padding()
    }
}

// MARK: - SettingsTab

enum SettingsTab: Hashable {
    case general
    case providers
    case prompts
    case logs
}

// MARK: - Preview

#Preview {
    SettingsView(
        settingsRepo: PreviewSettingsRepo(),
        keychainService: PreviewKeychainSvc(),
        promptRepo: PreviewPromptRepo()
    )
}

// MARK: - Preview Helpers

/// In-memory settings repository for SwiftUI previews.
private final class PreviewSettingsRepo: SettingsRepositoryProtocol,
    @unchecked Sendable
{
    private var current = AppSettings()
    var settings: AppSettings { current }
    func update(_ transform: (inout AppSettings) -> Void) {
        transform(&current)
    }
    func reset() { current = AppSettings() }
}

/// In-memory keychain service for SwiftUI previews.
private final class PreviewKeychainSvc: KeychainServiceProtocol,
    @unchecked Sendable
{
    private var store: [String: Data] = [:]
    func save(key: String, data: Data) throws { store[key] = data }
    func read(key: String) throws -> Data? { store[key] }
    func delete(key: String) throws { store[key] = nil }
}

/// In-memory prompt repository for SwiftUI previews.
private final class PreviewPromptRepo: PromptRepositoryProtocol,
    @unchecked Sendable
{
    private var prompts: [Prompt] = BuiltInPrompts.all
    func all() -> [Prompt] { prompts.filter { !$0.isHidden } }
    func allIncludingHidden() -> [Prompt] { prompts }
    func get(id: UUID) -> Prompt? { prompts.first { $0.id == id } }
    func save(_ prompt: Prompt) throws {
        if let idx = prompts.firstIndex(where: { $0.id == prompt.id }) {
            prompts[idx] = prompt
        } else {
            prompts.append(prompt)
        }
    }
    func delete(id: UUID) throws {
        prompts.removeAll { $0.id == id }
    }
    func hide(id: UUID) throws {
        if let idx = prompts.firstIndex(where: { $0.id == id }) {
            prompts[idx].isHidden = true
        }
    }
    func unhide(id: UUID) throws {
        if let idx = prompts.firstIndex(where: { $0.id == id }) {
            prompts[idx].isHidden = false
        }
    }
    func reorder(ids: [UUID]) throws {
        for (order, promptID) in ids.enumerated() {
            if let idx = prompts.firstIndex(where: { $0.id == promptID }) {
                prompts[idx].sortOrder = order
            }
        }
    }
    func search(query: String) -> [Prompt] {
        all().filter { $0.title.localizedCaseInsensitiveContains(query) }
    }
    func recentlyUsed(limit: Int) -> [Prompt] { [] }
}

// SettingsView.swift
// AITextTool
//
// Tab container for settings (General, Providers, Prompts, Logs).

import SwiftUI

struct SettingsView: View {
    let settingsRepo: SettingsRepositoryProtocol

    var body: some View {
        TabView {
            GeneralSettingsView(settingsRepo: settingsRepo)
                .tabItem {
                    Label(
                        Strings.Settings.general,
                        systemImage: "gear"
                    )
                }
                .accessibilityLabel(Strings.Settings.general)

            ProvidersSettingsView()
                .tabItem {
                    Label(
                        Strings.Settings.providers,
                        systemImage: "cpu"
                    )
                }
                .accessibilityLabel(Strings.Settings.providers)

            PromptsSettingsView()
                .tabItem {
                    Label(
                        Strings.Settings.prompts,
                        systemImage: "text.bubble"
                    )
                }
                .accessibilityLabel(Strings.Settings.prompts)

            LogsPlaceholderView()
                .tabItem {
                    Label(
                        Strings.Settings.logs,
                        systemImage: "doc.text"
                    )
                }
                .accessibilityLabel(Strings.Settings.logs)
        }
        .frame(width: 520, height: 420)
    }
}

// MARK: - Logs Placeholder

private struct LogsPlaceholderView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(Strings.Settings.noLogsMessage)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel(Strings.Settings.noLogsMessage)
    }
}

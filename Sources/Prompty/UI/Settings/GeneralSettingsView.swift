// GeneralSettingsView.swift
// Prompty
//
// Hotkey recorder (KeyboardShortcuts), Launch at Login (SMAppService),
// appearance picker, auto-copy toggle, result display override.
// SMAppService is used directly per spec (H5) -- no external package.

import KeyboardShortcuts
import ServiceManagement
import SwiftUI
import os

// MARK: - KeyboardShortcuts.Name extension

extension KeyboardShortcuts.Name {
    static let triggerAI = Self("triggerAI")
}

// MARK: - GeneralSettingsView

struct GeneralSettingsView: View {
    let settingsRepo: SettingsRepositoryProtocol

    @State private var launchAtLogin: Bool = false
    @State private var launchAtLoginError: String?
    @State private var appearance: PanelAppearance = .auto
    @State private var autoCopyOnDismiss: Bool = true
    @State private var renderModeOverride: ResultRenderMode?

    var body: some View {
        Form {
            hotkeySection
            loginSection
            appearanceSection
            autoCopySection
            renderModeSection
        }
        .formStyle(.grouped)
        .onAppear { loadSettings() }
    }

    // MARK: - Hotkey

    private var hotkeySection: some View {
        Section(Strings.Settings.hotkey) {
            KeyboardShortcuts.Recorder(
                Strings.Settings.hotkey,
                name: .triggerAI
            )
            .accessibilityLabel(Strings.Settings.hotkey)
        }
    }

    // MARK: - Launch at Login

    private var loginSection: some View {
        Section {
            Toggle(isOn: $launchAtLogin) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.Settings.launchAtLogin)
                    Text(Strings.Settings.launchAtLoginDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityLabel(Strings.Settings.launchAtLogin)
            .onChange(of: launchAtLogin) { _, newValue in
                updateLaunchAtLogin(enabled: newValue)
            }

            if let errorMessage = launchAtLoginError {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section(Strings.Settings.panelAppearance) {
            Picker(
                Strings.Settings.panelAppearance,
                selection: $appearance
            ) {
                Text(Strings.Settings.appearanceAuto)
                    .tag(PanelAppearance.auto)
                Text(Strings.Settings.appearanceLight)
                    .tag(PanelAppearance.light)
                Text(Strings.Settings.appearanceDark)
                    .tag(PanelAppearance.dark)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(Strings.Settings.panelAppearance)
            .onChange(of: appearance) { _, newValue in
                settingsRepo.update { $0.panelAppearance = newValue }
            }
        }
    }

    // MARK: - Auto-copy

    private var autoCopySection: some View {
        Section {
            Toggle(isOn: $autoCopyOnDismiss) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.Settings.autoCopyOnDismiss)
                    Text(Strings.Settings.autoCopyOnDismissDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityLabel(Strings.Settings.autoCopyOnDismiss)
            .onChange(of: autoCopyOnDismiss) { _, newValue in
                settingsRepo.update { $0.autoCopyOnDismiss = newValue }
            }
        }
    }

    // MARK: - Render Mode Override

    private var renderModeSection: some View {
        Section(Strings.Settings.resultDisplay) {
            Picker(
                Strings.Settings.resultDisplay,
                selection: $renderModeOverride
            ) {
                Text(Strings.Settings.usePerPromptSetting)
                    .tag(ResultRenderMode?.none)
                Text(Strings.Settings.alwaysPlainText)
                    .tag(ResultRenderMode?.some(.plain))
                Text(Strings.Settings.alwaysMarkdown)
                    .tag(ResultRenderMode?.some(.markdown))
            }
            .pickerStyle(.radioGroup)
            .onChange(of: renderModeOverride) { _, newValue in
                settingsRepo.update {
                    $0.resultRenderModeOverride = newValue
                }
            }
        }
    }

    // MARK: - Private

    private func loadSettings() {
        let current = settingsRepo.settings
        launchAtLogin = current.launchAtLogin
        appearance = current.panelAppearance
        autoCopyOnDismiss = current.autoCopyOnDismiss
        renderModeOverride = current.resultRenderModeOverride
    }

    private func updateLaunchAtLogin(enabled: Bool) {
        launchAtLoginError = nil
        let service = SMAppService.mainApp
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
            settingsRepo.update { $0.launchAtLogin = enabled }
            Logger.settings.info(
                "Launch at login \(enabled ? "enabled" : "disabled")"
            )
        } catch {
            launchAtLogin = !enabled
            launchAtLoginError = Strings.Settings.launchAtLoginError
            Logger.settings.error(
                "SMAppService failed: \(error.localizedDescription)"
            )
        }
    }
}

// MARK: - Preview

#Preview {
    GeneralSettingsView(settingsRepo: PreviewGeneralSettingsRepo())
        .frame(width: 480)
}

private final class PreviewGeneralSettingsRepo: SettingsRepositoryProtocol,
    @unchecked Sendable
{
    private var current = AppSettings()
    var settings: AppSettings { current }
    func update(_ transform: (inout AppSettings) -> Void) {
        transform(&current)
    }
    func reset() { current = AppSettings() }
}

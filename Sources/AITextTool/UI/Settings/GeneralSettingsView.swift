// GeneralSettingsView.swift
// AITextTool
//
// Launch at Login (SMAppService), appearance picker.
// SMAppService is used directly per spec (H5) -- no external package.

import ServiceManagement
import SwiftUI
import os

// MARK: - GeneralSettingsView

struct GeneralSettingsView: View {
    let settingsRepo: SettingsRepositoryProtocol

    @State private var launchAtLogin: Bool = false
    @State private var launchAtLoginError: String?
    @State private var appearance: PanelAppearance = .auto

    var body: some View {
        Form {
            loginSection
            appearanceSection
        }
        .formStyle(.grouped)
        .onAppear { loadSettings() }
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
                    .accessibilityLabel(errorMessage)
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

    // MARK: - Private

    private func loadSettings() {
        let current = settingsRepo.settings
        launchAtLogin = current.launchAtLogin
        appearance = current.panelAppearance
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

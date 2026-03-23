// PromptyApp.swift
// Prompty
//
// @main entry point. Creates AppState, AppDelegate, and wires dependencies.

import SwiftUI

@main
struct PromptyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(
                settingsRepo: SettingsRepository(),
                keychainService: KeychainService(),
                promptRepo: PromptRepository()
            )
        }
    }
}

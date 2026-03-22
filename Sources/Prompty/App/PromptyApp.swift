// PromptyApp.swift
// Prompty
//
// @main entry point. Creates AppState, AppDelegate, and wires dependencies.
// Agent app (LSUIElement = true) with no Dock icon, lives in menu bar only.

import SwiftUI

@main
struct PromptyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Menu bar agent app (LSUIElement = true) — no WindowGroup needed.
        // Settings scene registers Cmd+, automatically on macOS.
        Settings {
            Text(Strings.MenuBar.settings)
        }
    }
}

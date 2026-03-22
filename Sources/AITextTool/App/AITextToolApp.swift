// AITextToolApp.swift
// AITextTool
//
// @main entry point. Creates AppState, AppDelegate, and wires dependencies.

import SwiftUI

@main
struct AITextToolApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Menu bar agent app (LSUIElement = true) - no window group needed
        Settings {
            Text("Settings placeholder")
        }
    }
}

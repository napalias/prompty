// SettingsWindowController.swift
// Prompty
//
// NSWindowController that manages the settings window lifecycle.
// Opens via menu bar "Settings..." item. Standard macOS settings behavior.

import AppKit
import SwiftUI

// MARK: - SettingsWindowController

@MainActor
final class SettingsWindowController {
    private var window: NSWindow?
    private let settingsRepo: SettingsRepositoryProtocol
    private let keychainService: KeychainServiceProtocol
    private let promptRepo: PromptRepositoryProtocol

    init(
        settingsRepo: SettingsRepositoryProtocol,
        keychainService: KeychainServiceProtocol,
        promptRepo: PromptRepositoryProtocol
    ) {
        self.settingsRepo = settingsRepo
        self.keychainService = keychainService
        self.promptRepo = promptRepo
    }

    // MARK: - Public

    /// Shows the settings window, creating it if needed.
    func showSettings() {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }

        let settingsView = SettingsView(
            settingsRepo: settingsRepo,
            keychainService: keychainService,
            promptRepo: promptRepo
        )

        let hostingView = NSHostingView(rootView: settingsView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 520, height: 440)

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 440),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        newWindow.title = Strings.MenuBar.settings
            .replacingOccurrences(of: "...", with: "")
        newWindow.contentView = hostingView
        newWindow.center()
        newWindow.isReleasedWhenClosed = false

        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    /// Closes the settings window if open.
    func close() {
        window?.close()
    }
}

// MenuBarController.swift
// AITextTool
//
// NSStatusItem setup and menu management.
// Icon is set as template image for correct appearance in light/dark mode (H1).

import AppKit
import os
import Sparkle

@MainActor
final class MenuBarController {

    // MARK: - Properties

    private var statusItem: NSStatusItem?
    private let updaterController: SPUStandardUpdaterController

    // MARK: - Init

    init(updaterController: SPUStandardUpdaterController) {
        self.updaterController = updaterController
        setupStatusItem()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )

        guard let button = statusItem?.button else { return }

        // isTemplate = true ensures correct rendering in dark mode and selection
        let image = NSImage(
            systemSymbolName: "wand.and.stars",
            accessibilityDescription: "AITextTool"
        )
        image?.isTemplate = true
        button.image = image

        setupMenu()
    }

    private func setupMenu() {
        let menu = NSMenu()

        let checkForUpdatesItem = NSMenuItem(
            title: Strings.MenuBar.checkForUpdates,
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        checkForUpdatesItem.target = self
        menu.addItem(checkForUpdatesItem)

        let settingsItem = NSMenuItem(
            title: Strings.MenuBar.settings,
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: Strings.MenuBar.quit,
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    // MARK: - Actions

    @objc private func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    @objc private func openSettings() {
        Logger.ui.info("Settings requested from menu bar")
        NSApp.sendAction(
            Selector(("showSettingsWindow:")),
            to: nil,
            from: nil
        )
    }

    @objc private func quitApp() {
        Logger.app.info("Quit requested from menu bar")
        NSApp.terminate(nil)
    }
}

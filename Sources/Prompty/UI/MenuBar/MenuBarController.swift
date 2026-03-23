// MenuBarController.swift
// Prompty
//
// NSStatusItem setup and menu management.
// Icon is set as template image for correct appearance in light/dark mode (H1).

import AppKit
import os

@MainActor
final class MenuBarController: NSObject {

    // MARK: - Properties

    private var statusItem: NSStatusItem?
    private let sessionRepo: SessionHistoryRepositoryProtocol

    // MARK: - Init

    init(
        sessionRepo: SessionHistoryRepositoryProtocol = SessionHistoryRepository()
    ) {
        self.sessionRepo = sessionRepo
        super.init()
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
            accessibilityDescription: "Prompty"
        )
        image?.isTemplate = true
        button.image = image

        setupMenu()
    }

    private func setupMenu() {
        let menu = NSMenu()
        menu.delegate = self

        let settingsItem = NSMenuItem(
            title: Strings.MenuBar.settings,
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let historyItem = NSMenuItem(
            title: Strings.MenuBar.history,
            action: nil,
            keyEquivalent: ""
        )
        historyItem.submenu = buildHistorySubmenu()
        historyItem.tag = MenuItemTag.history.rawValue
        menu.addItem(historyItem)

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

    private func buildHistorySubmenu() -> NSMenu {
        let submenu = NSMenu(title: Strings.MenuBar.history)
        let sessions = Array(sessionRepo.all().prefix(5))

        if sessions.isEmpty {
            let emptyItem = NSMenuItem(
                title: Strings.History.noHistory,
                action: nil,
                keyEquivalent: ""
            )
            emptyItem.isEnabled = false
            submenu.addItem(emptyItem)
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .none

            for session in sessions {
                let title = "\(session.promptTitle) on '\(session.summary)'"
                let truncatedTitle = title.count > 60
                    ? String(title.prefix(57)) + "..."
                    : title
                let item = NSMenuItem(
                    title: truncatedTitle,
                    action: nil,
                    keyEquivalent: ""
                )
                item.toolTip = dateFormatter.string(from: session.createdAt)
                submenu.addItem(item)
            }

            submenu.addItem(NSMenuItem.separator())

            let clearItem = NSMenuItem(
                title: Strings.History.clearHistory,
                action: #selector(clearHistory),
                keyEquivalent: ""
            )
            clearItem.target = self
            submenu.addItem(clearItem)
        }

        return submenu
    }

    // MARK: - Actions

    @objc private func openSettings() {
        Logger.ui.info("Settings requested from menu bar")
        NSApp.sendAction(
            Selector(("showSettingsWindow:")),
            to: nil,
            from: nil
        )
    }

    @objc private func clearHistory() {
        Logger.history.info("Clear history requested from menu bar")
        try? sessionRepo.deleteAll()
    }

    @objc private func quitApp() {
        Logger.app.info("Quit requested from menu bar")
        NSApp.terminate(nil)
    }
}

// MARK: - Menu Item Tags

private enum MenuItemTag: Int {
    case history = 100
}

// MARK: - NSMenuDelegate

extension MenuBarController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        if let historyItem = menu.item(withTag: MenuItemTag.history.rawValue) {
            historyItem.submenu = buildHistorySubmenu()
        }
    }
}

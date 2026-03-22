// AppDelegate.swift
// AITextTool
//
// NSApplicationDelegate. Holds references to core services and controllers.
// AITextTool collects no analytics, telemetry, or usage data.
// No third-party tracking SDKs are used.
// All data (prompts, history, logs, API keys) is stored locally on this device only.

import AppKit
import os

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Controllers

    private var menuBarController: MenuBarController?

    // MARK: - State

    let appState = AppState()

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure no Dock icon for this agent app
        NSApp.setActivationPolicy(.accessory)

        menuBarController = MenuBarController()

        Logger.app.info("Application launched")
    }

    func applicationShouldTerminate(
        _ sender: NSApplication
    ) -> NSApplication.TerminateReply {
        if appState.isStreaming {
            appState.cancelStreaming()
        }
        return .terminateNow
    }
}

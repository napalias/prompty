// AppDelegate.swift
// AITextTool
//
// NSApplicationDelegate. Holds references to core services and controllers.
// AITextTool collects no analytics, telemetry, or usage data.
// No third-party tracking SDKs are used.
// All data (prompts, history, logs, API keys) is stored locally on this device only.

import AppKit
import os
import Sparkle

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Controllers

    private var menuBarController: MenuBarController?
    private var updaterController: SPUStandardUpdaterController!

    // MARK: - State

    let appState = AppState()

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure no Dock icon for this agent app
        NSApp.setActivationPolicy(.accessory)

        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        menuBarController = MenuBarController(updaterController: updaterController)

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

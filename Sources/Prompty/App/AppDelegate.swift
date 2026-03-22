// AppDelegate.swift
// Prompty
//
// NSApplicationDelegate. Holds references to core services and controllers.
// Prompty collects no analytics, telemetry, or usage data.
// No third-party tracking SDKs are used.
// All data (prompts, history, logs, API keys) is stored locally on this device only.

import AppKit
import os
import Sparkle
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Controllers

    private var menuBarController: MenuBarController?
    private var updaterController: SPUStandardUpdaterController!

    // MARK: - Services

    private let hotkeyManager: HotkeyManagerProtocol
    private let instanceChecker: SingleInstanceCheckerProtocol

    // MARK: - State

    let appState = AppState()

    // MARK: - Onboarding

    private var onboardingWindow: NSWindow?

    // MARK: - Init

    override convenience init() {
        self.init(
            hotkeyManager: HotkeyManager(),
            instanceChecker: SingleInstanceChecker()
        )
    }

    init(
        hotkeyManager: HotkeyManagerProtocol,
        instanceChecker: SingleInstanceCheckerProtocol
    ) {
        self.hotkeyManager = hotkeyManager
        self.instanceChecker = instanceChecker
        super.init()
    }

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Enforce single instance before any other setup (19C)
        if instanceChecker.isDuplicateRunning() {
            Logger.app.warning("Duplicate instance detected — terminating")
            let alert = NSAlert()
            alert.messageText = Strings.SingleInstance.alreadyRunning
            alert.informativeText = Strings.SingleInstance.findInMenuBar
            alert.runModal()
            NSApp.terminate(nil)
            return
        }

        NSApp.setActivationPolicy(.accessory)

        // Initialize crash reporter (local only, no telemetry per 17B)
        _ = CrashReporter.shared

        // Register for sleep/wake to re-register hotkey (19B)
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        menuBarController = MenuBarController(updaterController: updaterController)

        // Show onboarding on first launch (18D)
        if !OnboardingViewModel.hasCompletedOnboarding {
            showOnboarding()
        }

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

    // MARK: - Sleep/Wake (19B)

    @objc func systemDidWake() {
        Logger.app.info("System woke from sleep — re-registering hotkey")
        do {
            try hotkeyManager.reregister()
        } catch {
            Logger.app.error(
                "Failed to re-register hotkey after wake: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Onboarding (18D)

    private func showOnboarding() {
        let onboardingView = OnboardingView()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 460),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = Strings.Onboarding.welcomeTitle
        window.contentView = NSHostingView(rootView: onboardingView)
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindow = window
    }
}

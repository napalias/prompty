// AppDelegate.swift
// Prompty
//
// NSApplicationDelegate. Holds references to core services and controllers.
// Prompty collects no analytics, telemetry, or usage data.
// No third-party tracking SDKs are used.
// All data (prompts, history, logs, API keys) is stored locally on this device only.

import AppKit
import os
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Controllers

    private var menuBarController: MenuBarController?
    private var panelController: FloatingPanelController?

    // MARK: - Services

    private let hotkeyManager: HotkeyManagerProtocol
    private let instanceChecker: SingleInstanceCheckerProtocol
    private let textCapture: TextCaptureService
    private let settingsRepo: SettingsRepository

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
        self.textCapture = TextCaptureService()
        self.settingsRepo = SettingsRepository()
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

        NSApp.setActivationPolicy(.regular)

        // Initialize crash reporter (local only, no telemetry per 17B)
        _ = CrashReporter.shared

        // Register for sleep/wake to re-register hotkey (19B)
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        menuBarController = MenuBarController()

        // Register the global hotkey
        registerHotkey()

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

    // MARK: - Hotkey Registration

    private func registerHotkey() {
        let settings = settingsRepo.settings
        let hotkey = settings.hotkey

        hotkeyManager.onHotkeyFired = { [weak self] in
            Task { @MainActor in
                self?.handleHotkeyFired()
            }
        }

        do {
            try hotkeyManager.register(
                keyCode: CGKeyCode(hotkey.keyCode),
                modifiers: CGEventFlags(rawValue: hotkey.modifiers)
            )
            Logger.hotkey.info("Hotkey registered: keyCode=\(hotkey.keyCode)")
        } catch {
            Logger.hotkey.error("Failed to register hotkey: \(error.localizedDescription)")
            // Show alert about Input Monitoring permission
            let alert = NSAlert()
            alert.messageText = Strings.Errors.inputMonitoringPermissionDenied
            alert.informativeText = "Go to System Settings → Privacy & Security → Input Monitoring and enable Prompty."
            alert.addButton(withTitle: Strings.Errors.openSystemSettings)
            alert.addButton(withTitle: "OK")
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(
                    URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!
                )
            }
        }
    }

    private func handleHotkeyFired() {
        Logger.hotkey.info("Hotkey fired — capturing text")

        Task { @MainActor in
            do {
                let text = try await textCapture.capture()
                appState.reset(capturedText: text)
                appState.panelMode = .promptPicker
                appState.isVisible = true

                // Show the floating panel
                let cursorPoint = NSEvent.mouseLocation
                if panelController == nil {
                    panelController = FloatingPanelController(
                        textCapture: textCapture,
                        aiManager: AIProviderManager(),
                        promptRepo: PromptRepository(),
                        state: appState
                    )
                }
                panelController?.show(near: cursorPoint)

                Logger.hotkey.info("Text captured (\(text.count) chars), panel shown")
            } catch let error as AppError {
                Logger.hotkey.error("Text capture failed: \(error.localizedDescription)")
                if error == .noTextSelected {
                    // Show toast
                    Logger.hotkey.info("No text selected — showing toast")
                }
            } catch {
                Logger.hotkey.error("Unexpected error: \(error.localizedDescription)")
            }
        }
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
            defer: fal rderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindow = window
    }
}
 

// PermissionChecker.swift
// Prompty
//
// Checks and requests Accessibility and Input Monitoring permissions.

import ApplicationServices
import Foundation

/// Protocol for checking system permissions.
/// Enables mock injection for testing.
protocol PermissionChecking {
    var isAccessibilityGranted: Bool { get }
    func requestAccessibilityIfNeeded()
    func requestInputMonitoringIfNeeded()
}

final class PermissionChecker: PermissionChecking {
    /// Returns true if the process is trusted for accessibility access.
    var isAccessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    /// Prompts for Accessibility access if not already granted.
    func requestAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true
        ] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    /// Prompts for Input Monitoring access if not already granted.
    func requestInputMonitoringIfNeeded() {
        // Input monitoring permission is implicitly requested when
        // CGEvent.tapCreate is called. No separate API exists.
    }
}

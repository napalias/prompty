// PermissionChecker.swift
// AITextTool
//
// Checks and requests Accessibility and Input Monitoring permissions.

import Foundation

final class PermissionChecker {
    /// Prompts for Accessibility access if not already granted.
    func requestAccessibilityIfNeeded() {
        // TODO: Implement AXIsProcessTrustedWithOptions
    }

    /// Prompts for Input Monitoring access if not already granted.
    func requestInputMonitoringIfNeeded() {
        // TODO: Implement IOHIDCheckAccess
    }
}

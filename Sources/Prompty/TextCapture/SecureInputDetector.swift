// SecureInputDetector.swift
// Prompty
//
// Detects whether secure keyboard input is active system-wide (16B).

import Carbon

/// Protocol for detecting secure input mode.
/// Enables mock injection for testing.
protocol SecureInputDetecting {
    var isActive: Bool { get }
}

struct SecureInputDetector: SecureInputDetecting {
    /// Returns true if any app has activated secure keyboard input.
    /// Uses the Carbon function IsSecureEventInputEnabled().
    var isActive: Bool {
        IsSecureEventInputEnabled()
    }
}

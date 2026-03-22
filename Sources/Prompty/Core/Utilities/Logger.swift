// Logger.swift
// Prompty
//
// Thin os.Logger wrapper. Single subsystem, one category per module.
// NEVER log user content at any level (review checklist F3).

import Foundation
import os

/// Subsystem derived from bundle identifier at runtime.
private let subsystem = Bundle.main.bundleIdentifier ?? "com.prompty"

extension Logger {
    /// General application lifecycle events.
    static let app = Logger(subsystem: subsystem, category: "app")
    /// Hotkey registration, firing, and re-registration.
    static let hotkey = Logger(subsystem: subsystem, category: "hotkey")
    /// Text capture via AX API and clipboard fallback.
    static let capture = Logger(subsystem: subsystem, category: "capture")
    /// AI provider requests, streaming, and responses.
    static let ai = Logger(subsystem: subsystem, category: "ai")
    /// Node.js sidecar process lifecycle.
    static let sidecar = Logger(subsystem: subsystem, category: "sidecar")
    /// UI panel show/hide, positioning, animations.
    static let ui = Logger(subsystem: subsystem, category: "ui")
    /// Settings and Keychain read/write operations.
    static let settings = Logger(subsystem: subsystem, category: "settings")
    /// Session history persistence.
    static let history = Logger(subsystem: subsystem, category: "history")
    /// Sparkle auto-update checks.
    static let update = Logger(subsystem: subsystem, category: "update")
}

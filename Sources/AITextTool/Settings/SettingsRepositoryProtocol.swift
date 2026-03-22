// SettingsRepositoryProtocol.swift
// AITextTool
//
// Protocol for reading and writing app settings.

import Foundation

/// Protocol for reading and writing app settings.
/// Implementations must be safe to call from any thread.
protocol SettingsRepositoryProtocol: Sendable {
    /// Current persisted settings (or defaults on first launch).
    var settings: AppSettings { get }

    /// Atomically update settings via a transform closure.
    /// The closure receives an inout copy; the result is persisted.
    func update(_ transform: (inout AppSettings) -> Void)

    /// Reset all settings to factory defaults.
    func reset()
}

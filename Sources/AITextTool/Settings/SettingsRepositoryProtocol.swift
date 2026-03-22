// SettingsRepositoryProtocol.swift
// AITextTool

import Foundation

/// Protocol for reading and writing app settings.
protocol SettingsRepositoryProtocol {
    /// Loads persisted settings or returns defaults.
    func load() -> AppSettings
    /// Saves settings to persistent storage.
    func save(_ settings: AppSettings) throws
}

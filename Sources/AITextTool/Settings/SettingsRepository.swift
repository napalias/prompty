// SettingsRepository.swift
// AITextTool
//
// UserDefaults-based settings persistence.

import Foundation
import os

final class SettingsRepository: SettingsRepositoryProtocol {
    private let defaults: UserDefaults
    private static let settingsKey = "app_settings"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> AppSettings {
        guard let data = defaults.data(forKey: Self.settingsKey) else {
            return AppSettings()
        }
        do {
            return try JSONDecoder().decode(AppSettings.self, from: data)
        } catch {
            Logger.settings.error("Failed to decode AppSettings: \(error). Using defaults.")
            // Backup corrupt data before overwriting (21F)
            let backupKey = "app_settings_backup_\(Date().timeIntervalSince1970)"
            defaults.set(data, forKey: backupKey)
            return AppSettings()
        }
    }

    func save(_ settings: AppSettings) throws {
        let data = try JSONEncoder().encode(settings)
        defaults.set(data, forKey: Self.settingsKey)
    }
}

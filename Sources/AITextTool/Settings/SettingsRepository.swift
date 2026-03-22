// SettingsRepository.swift
// AITextTool
//
// UserDefaults-backed settings persistence with Codable encode/decode.
// Accepts an injected UserDefaults instance for test isolation.

import Foundation
import os

// MARK: - SettingsRepository

final class SettingsRepository: SettingsRepositoryProtocol, @unchecked Sendable {
    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    /// Lock protects cached settings for thread safety.
    private let lock = NSLock()
    private var cached: AppSettings?

    static let settingsKey = "app_settings"

    // MARK: - Init

    /// Creates a repository backed by the given UserDefaults suite.
    /// Tests inject an ephemeral suite; production uses `.standard`.
    init(
        defaults: UserDefaults = .standard,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.defaults = defaults
        self.encoder = encoder
        self.decoder = decoder
    }

    // MARK: - SettingsRepositoryProtocol

    var settings: AppSettings {
        lock.lock()
        defer { lock.unlock() }

        if let cached {
            return cached
        }
        let loaded = loadFromDefaults()
        cached = loaded
        return loaded
    }

    func update(_ transform: (inout AppSettings) -> Void) {
        lock.lock()
        var current = cached ?? loadFromDefaults()
        transform(&current)
        persist(current)
        cached = current
        lock.unlock()
    }

    func reset() {
        lock.lock()
        let defaultSettings = AppSettings()
        persist(defaultSettings)
        cached = defaultSettings
        lock.unlock()
    }

    // MARK: - Private

    private func loadFromDefaults() -> AppSettings {
        guard let data = defaults.data(forKey: Self.settingsKey) else {
            return AppSettings()
        }
        do {
            return try decoder.decode(AppSettings.self, from: data)
        } catch {
            Logger.settings.error("Failed to decode AppSettings: \(error.localizedDescription). Using defaults.")
            // Backup corrupt data before overwriting (21F resilience)
            let backupKey = "app_settings_backup_\(Int(Date().timeIntervalSince1970))"
            defaults.set(data, forKey: backupKey)
            return AppSettings()
        }
    }

    private func persist(_ settings: AppSettings) {
        do {
            let data = try encoder.encode(settings)
            defaults.set(data, forKey: Self.settingsKey)
        } catch {
            Logger.settings.error("Failed to encode AppSettings: \(error.localizedDescription)")
        }
    }
}

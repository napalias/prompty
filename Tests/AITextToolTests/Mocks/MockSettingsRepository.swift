// MockSettingsRepository.swift
// AITextToolTests

@testable import AITextTool

final class MockSettingsRepository: SettingsRepositoryProtocol {
    var savedSettings: AppSettings?

    func load() -> AppSettings {
        savedSettings ?? AppSettings()
    }

    func save(_ settings: AppSettings) throws {
        savedSettings = settings
    }
}

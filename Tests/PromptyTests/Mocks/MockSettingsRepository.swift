// MockSettingsRepository.swift
// PromptyTests
//
// In-memory mock for SettingsRepositoryProtocol. Tracks calls for assertions.

@testable import Prompty

final class MockSettingsRepository: SettingsRepositoryProtocol, @unchecked Sendable {
    private var storedSettings: AppSettings = AppSettings()
    var updateCallCount = 0
    var resetCallCount = 0

    var settings: AppSettings {
        storedSettings
    }

    func update(_ transform: (inout AppSettings) -> Void) {
        updateCallCount += 1
        transform(&storedSettings)
    }

    func reset() {
        resetCallCount += 1
        storedSettings = AppSettings()
    }
}

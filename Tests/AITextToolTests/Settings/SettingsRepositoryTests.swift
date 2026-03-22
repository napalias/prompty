// SettingsRepositoryTests.swift
// AITextToolTests
//
// Tests SettingsRepository using isolated UserDefaults suites.
// Pattern from 12_TESTING.md: inject ephemeral suite, tear down after each test.

import XCTest
@testable import AITextTool

final class SettingsRepositoryTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var repo: SettingsRepository!

    override func setUp() {
        super.setUp()
        suiteName = "test-\(UUID().uuidString)"
        // Force-unwrap justified: UserDefaults(suiteName:) only fails for invalid names
        defaults = UserDefaults(suiteName: suiteName)!
        repo = SettingsRepository(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        repo = nil
        super.tearDown()
    }

    // MARK: - test_defaultSettings

    func test_defaultSettings() {
        let settings = repo.settings

        XCTAssertEqual(settings.activeProviderID, "anthropic-api")
        XCTAssertFalse(settings.launchAtLogin)
        XCTAssertEqual(settings.hotkey.keyCode, 49)
        XCTAssertEqual(settings.hotkey.modifiers, 524_288)
        XCTAssertEqual(settings.panelAppearance, .auto)
        XCTAssertTrue(settings.autoCopyOnDismiss)
        XCTAssertFalse(settings.defaultSystemPrompt.isEmpty)
        XCTAssertTrue(settings.selectedModelPerProvider.isEmpty)
    }

    // MARK: - test_updateSettings_persists

    func test_updateSettings_persists() {
        repo.update { settings in
            settings.activeProviderID = "openai"
            settings.launchAtLogin = true
            settings.autoCopyOnDismiss = false
            settings.selectedModelPerProvider["openai"] = "gpt-4o"
        }

        // Create a fresh repo reading from the same defaults to verify persistence
        let freshRepo = SettingsRepository(defaults: defaults)
        let loaded = freshRepo.settings

        XCTAssertEqual(loaded.activeProviderID, "openai")
        XCTAssertTrue(loaded.launchAtLogin)
        XCTAssertFalse(loaded.autoCopyOnDismiss)
        XCTAssertEqual(loaded.selectedModelPerProvider["openai"], "gpt-4o")
    }

    // MARK: - test_resetSettings_restoresDefaults

    func test_resetSettings_restoresDefaults() {
        // First modify settings
        repo.update { settings in
            settings.activeProviderID = "ollama"
            settings.launchAtLogin = true
            settings.panelAppearance = .dark
        }

        XCTAssertEqual(repo.settings.activeProviderID, "ollama")

        // Reset
        repo.reset()

        let settings = repo.settings
        XCTAssertEqual(settings.activeProviderID, "anthropic-api")
        XCTAssertFalse(settings.launchAtLogin)
        XCTAssertEqual(settings.panelAppearance, .auto)

        // Verify persistence of reset through a fresh repo
        let freshRepo = SettingsRepository(defaults: defaults)
        XCTAssertEqual(freshRepo.settings, AppSettings())
    }
}

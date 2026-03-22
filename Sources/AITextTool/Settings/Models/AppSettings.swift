// AppSettings.swift
// AITextTool

import Foundation

/// Codable settings value type persisted in UserDefaults.
struct AppSettings: Codable, Equatable, Sendable {
    var hotkey: HotkeySetting = HotkeySetting()
    var activeProviderID: String = "anthropic-api"
    var providerConfigs: [String: ProviderConfig] = [:]
    var launchAtLogin: Bool = false
    var panelAppearance: PanelAppearance = .auto
    var resultRenderModeOverride: ResultRenderMode?
}

/// Persisted hotkey configuration.
struct HotkeySetting: Codable, Equatable, Sendable {
    var keyCode: UInt16 = 49
    var modifiers: UInt64 = 524288
}

/// Provider-specific configuration.
struct ProviderConfig: Codable, Equatable, Sendable {
    let providerID: String
    var isEnabled: Bool = true
    var modelOverride: String?
    var customBaseURL: String?
}

/// Panel light/dark mode appearance setting.
enum PanelAppearance: String, Codable, Sendable {
    case auto
    case light
    case dark
}

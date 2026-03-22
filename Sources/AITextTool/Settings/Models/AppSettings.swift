// AppSettings.swift
// AITextTool
//
// Codable settings value type persisted in UserDefaults.
// All fields have sensible defaults for first-launch experience.

import Foundation

// MARK: - AppSettings

/// Codable settings value type persisted in UserDefaults.
struct AppSettings: Codable, Equatable, Sendable {
    /// The hotkey key code and modifier flags.
    var hotkey: HotkeySetting = HotkeySetting()

    /// ID of the currently active AI provider (e.g. "anthropic-api", "openai", "ollama").
    var activeProviderID: String = "anthropic-api"

    /// Per-provider configuration (API keys stored separately in Keychain).
    var providerConfigs: [String: ProviderConfig] = [:]

    /// Whether the app should launch at login via SMAppService.
    var launchAtLogin: Bool = false

    /// Panel appearance override (auto follows system).
    var panelAppearance: PanelAppearance = .auto

    /// Global override for result rendering (nil = use per-prompt setting).
    var resultRenderModeOverride: ResultRenderMode?

    /// Selected model identifier per provider ID (e.g. "openai": "gpt-4o").
    var selectedModelPerProvider: [String: String] = [:]

    /// Automatically copy result to clipboard when panel is dismissed via Escape (19G).
    var autoCopyOnDismiss: Bool = true

    /// Default system prompt sent to all providers unless overridden per-prompt (19K).
    var defaultSystemPrompt: String = """
        You are a precise text transformation assistant. \
        When given a task and text, output ONLY the transformed result. \
        Do not include any preamble, explanation, sign-off, or meta-commentary. \
        Do not say "Here is...", "Certainly!", "Sure!", or similar. \
        Respond with the transformed text and nothing else.
        """
}

// MARK: - HotkeySetting

/// Persisted hotkey configuration.
/// Default: Option+Space (keyCode 49 = Space, modifiers = maskAlternate).
struct HotkeySetting: Codable, Equatable, Sendable {
    /// CGKeyCode for the hotkey. 49 = Space bar.
    var keyCode: UInt16 = 49
    /// CGEventFlags raw value. 524288 = maskAlternate (Option key).
    var modifiers: UInt64 = 524_288
}

// MARK: - ProviderConfig

/// Provider-specific configuration stored alongside settings.
struct ProviderConfig: Codable, Equatable, Sendable {
    /// Provider identifier matching AIProviderProtocol.id.
    let providerID: String
    /// Whether this provider is enabled in the provider list.
    var isEnabled: Bool = true
    /// Override the default model for this provider.
    var modelOverride: String?
    /// Custom base URL for OpenAI-compatible endpoints (19J).
    var customBaseURL: String?
}

// MARK: - PanelAppearance

/// Panel light/dark mode appearance setting.
enum PanelAppearance: String, Codable, Sendable, CaseIterable {
    case auto
    case light
    case dark
}

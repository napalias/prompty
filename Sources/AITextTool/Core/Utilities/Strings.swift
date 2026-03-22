// Strings.swift
// AITextTool
//
// ALL user-facing string constants. No hardcoded English strings in view files.

// swiftlint:disable type_body_length

enum Strings {

    enum Panel {
        static let noTextSelected = "No text selected"
        static let thinking = "Thinking..."
        static let copied = "Copied to clipboard"
        static let retrying = "Retrying..."
        static let stopStreaming = "Stop"
        static let searchPrompts = "Search prompts..."
        static let noPromptsMatch = "No prompts match your search"
        static let customPrompt = "Custom Prompt"
        static let send = "Send"
        static let back = "Back"
        static let noProviderDetail = "Add an API key or connect Claude in Settings to start using AITextTool."
        static let customPromptInputLabel = "Custom prompt input"
    }

    enum ActionBar {
        static let replace = "Replace"
        static let copy = "Copy"
        static let diff = "Diff"
        static let edit = "Edit"
        static let dismiss = "Dismiss"
        static let accept = "Accept"
        static let reject = "Reject"
        static let continuePrompting = "Continue"
    }

    enum ContinueChat {
        static let followUpPlaceholder = "Ask a follow-up..."
        static let send = "Send"
        static let startOver = "Start Over"
        static let you = "You"
        static let assistant = "Assistant"
    }

    enum Errors {
        static let noTextSelectedMessage = "No text selected"
        static let noTextSelectedDetail = "Select some text in any app, then press the hotkey."
        static let secureInputTitle = "Secure input active"
        static let secureInputDetail = "Click away from the password field first, then try again."
        static let providerNotConfigured = "Provider not configured"
        static let networkUnavailable = "No internet connection"
        static let rateLimited = "Rate limit reached"
        static let oauthExpired = "Subscription session expired"
        static let oauthExpiredDetail = "Run 'claude login' in Terminal to reconnect."
        static let ollamaNotRunning = "Ollama is not running"
        static let ollamaNotRunningDetail = "Open Terminal and run: ollama serve"
        static let accessibilityPermissionDenied = "Accessibility permission required"
        static let inputMonitoringPermissionDenied = "Input Monitoring permission required"
        static let textCaptureTimeout = "Text capture timed out"
    }

    enum Settings {
        static let apiKeyPlaceholder = "sk-..."
        static let baseURLPlaceholder = "https://api.openai.com/v1"
        static let hotkeyDefault = "Option+Space"
        static let noLogsMessage = "No log files yet"
        static let general = "General"
        static let providers = "Providers"
        static let prompts = "Prompts"
        static let logs = "Logs"
        static let launchAtLogin = "Launch at Login"
        static let launchAtLoginDescription = "Automatically start AITextTool when you log in."
        static let launchAtLoginError = "Could not update login item"
        static let panelAppearance = "Panel Appearance"
        static let appearanceAuto = "Auto"
        static let appearanceLight = "Light"
        static let appearanceDark = "Dark"
        static let hotkey = "Hotkey"
    }

    enum PromptPicker {
        static let searchPlaceholder = "Search prompts..."
        static let recentlyUsed = "Recently Used"
        static let allPrompts = "All Prompts"
        static let noResults = "No prompts match your search"
        static let noResultsDetail = "Try a different search term."
    }

    enum Accessibility {
        static let panelLabel = "AITextTool Panel"
        static let searchField = "Search prompts"
        static let clearSearch = "Clear search"
        static let promptList = "Prompt list"
    }

    enum Diff {
        static let original = "Original"
        static let revised = "Revised"
    }

    enum EditBeforeReplace {
        static let title = "Edit before replacing"
    }

    enum MenuBar {
        static let checkForUpdates = "Check for Updates..."
        static let settings = "Settings..."
        static let history = "History"
        static let quit = "Quit AITextTool"
        static let hotkeyHint = "Hotkey: Option+Space"
    }
}

// swiftlint:enable type_body_length

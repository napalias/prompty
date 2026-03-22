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

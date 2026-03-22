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
        static let noProviderDetail = "Configure an AI provider in Settings to get started."
        static let customPromptInputLabel = "Enter your prompt"
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
        static let streamInterrupted = "Stream interrupted"
        static let retry = "Retry"
        static let openSystemSettings = "Open System Settings"
        static let openSettings = "Open Settings"
        static let checkApiKey = "Check API Key"
        static let copyCommand = "Copy Command"
        static let ollamaServeCommand = "ollama serve"
        static let claudeLoginCommand = "claude login"
    }

    enum PromptPicker {
        static let searchPlaceholder = "Search prompts..."
        static let recentlyUsed = "Recently Used"
        static let allPrompts = "All Prompts"
        static let noResults = "No prompts found"
        static let noResultsDetail = "Try a different search term"
    }

    enum ContinueChat {
        static let followUpPlaceholder = "Ask a follow-up..."
        static let send = "Send"
        static let startOver = "Start Over"
        static let you = "You"
        static let assistant = "Assistant"
    }

    enum Diff {
        static let original = "Original"
        static let revised = "Revised"
        static let accept = "Accept"
        static let reject = "Reject"
        static let edit = "Edit"
    }

    enum EditBeforeReplace {
        static let title = "Edit Before Replacing"
        static let confirm = "Replace"
        static let cancel = "Cancel"
    }

    enum Accessibility {
        static let panelLabel = "AITextTool floating panel"
        static let searchField = "Search prompts"
        static let clearSearch = "Clear search"
        static let promptList = "Prompt list"
    }

    enum Settings {
        static let apiKeyPlaceholder = "sk-..."
        static let baseURLPlaceholder = "https://api.openai.com/v1"
        static let hotkeyDefault = "Option+Space"
        static let noLogsMessage = "No log files yet"
        static let general = "General"
        static let providers = "Providers"
        static let prompts = "Prompts"
        static let hotkey = "Hotkey"
        static let launchAtLogin = "Launch at Login"
        static let launchAtLoginDescription = "Automatically start AITextTool when you log in."
        static let launchAtLoginError = "Could not update login item"
        static let panelAppearance = "Panel Appearance"
        static let appearanceAuto = "Auto"
        static let appearanceLight = "Light"
        static let appearanceDark = "Dark"
        static let autoCopyOnDismiss = "Auto-copy on dismiss"
        static let autoCopyOnDismissDescription = "Copy AI result to clipboard when panel is dismissed with Escape."
        static let resultDisplay = "Result Display"
        static let usePerPromptSetting = "Use per-prompt setting"
        static let alwaysPlainText = "Always plain text"
        static let alwaysMarkdown = "Always markdown"
        static let anthropicApiKey = "Anthropic API Key"
        static let openaiApiKey = "OpenAI API Key"
        static let ollamaBaseURL = "Ollama URL"
        static let ollamaBaseURLDefault = "http://localhost:11434"
        static let model = "Model"
        static let testConnection = "Test Connection"
        static let connectionSuccess = "Connected successfully"
        static let connectionFailed = "Connection failed"
        static let testing = "Testing..."
        static let customBaseURL = "Base URL"
        static let quickFill = "Quick-fill:"
        static let quickFillOpenAI = "OpenAI"
        static let quickFillGroq = "Groq"
        static let quickFillLMStudio = "LM Studio"
        static let addPrompt = "New Prompt"
        static let editPrompt = "Edit"
        static let deletePrompt = "Delete"
        static let restorePrompt = "Restore"
        static let importPrompts = "Import JSON"
        static let exportPrompts = "Export JSON"
        static let myPrompts = "My Prompts"
        static let builtInPrompts = "Built-in"
        static let hiddenPrompts = "Hidden"
        static let confirmDelete = "Delete this prompt?"
        static let confirmDeleteMessage = "This action cannot be undone."
        static let title = "Title"
        static let icon = "Icon"
        static let template = "Template"
        static let resultMode = "After response"
        static let renderMode = "Display mode"
        static let pasteMode = "Paste format"
    }

    enum Logs {
        static let title = "Log Files"
        static let privacyNote = "Logs are stored locally on this device and are never sent anywhere."
        static let openFolder = "Open Logs Folder"
        static let deleteAll = "Delete All"
        static let deleteConfirmTitle = "Delete all log files?"
        static let deleteConfirmMessage = "This action cannot be undone. All crash reports and error logs will be permanently deleted."
        static let cancel = "Cancel"
        static let openInConsole = "Open in Console"
        static let logs = "Logs"
    }

    enum MenuBar {
        static let checkForUpdates = "Check for Updates..."
        static let settings = "Settings..."
        static let history = "History"
        static let quit = "Quit AITextTool"
        static let hotkeyHint = "Hotkey: Option+Space"
    }

    enum History {
        static let noHistory = "No recent sessions"
        static let showAll = "Show All History..."
        static let clearHistory = "Clear History..."
    }
}

// swiftlint:enable type_body_length

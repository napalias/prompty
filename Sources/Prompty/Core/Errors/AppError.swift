// AppError.swift
// Prompty
//
// Typed error enum for the whole app. All services throw AppError only.
// No raw NSError or URLError propagated to callers.

import Foundation

/// Exhaustive error type for Prompty. No stringly-typed errors.
enum AppError: LocalizedError, Equatable {

    // MARK: - Text Capture

    /// Accessibility permission not granted by user.
    case accessibilityPermissionDenied

    /// Input Monitoring permission not granted (CGEventTap).
    case inputMonitoringPermissionDenied

    /// No text was selected in the frontmost application.
    case noTextSelected

    /// Text capture timed out waiting for AX or clipboard response.
    case textCaptureTimeout

    /// A secure input field (password, etc.) is active system-wide (16B).
    case secureInputActive

    // MARK: - AI Providers

    /// The specified provider has no API key or is not configured.
    case providerNotConfigured(providerID: String)

    /// Device has no internet connection.
    case networkUnavailable

    /// The provided API key is invalid or revoked.
    case apiKeyInvalid(providerID: String)

    /// API rate limit exceeded for the provider.
    case rateLimitExceeded(providerID: String)

    /// Generic API error with provider context.
    case apiError(providerID: String, message: String)

    /// Ollama is not running on localhost.
    case ollamaNotRunning

    /// Ollama model is not pulled/installed (18I).
    case ollamaModelNotFound(modelName: String)

    /// Streaming connection was interrupted unexpectedly.
    case streamInterrupted

    /// Claude OAuth token has expired (19D).
    case oauthTokenExpired

    // MARK: - Text Replace

    /// Cannot replace text in the given application.
    case cannotReplaceInApp(appName: String)

    // MARK: - Settings / Keychain

    /// Failed to read from macOS Keychain.
    case keychainReadFailed

    /// Failed to write to macOS Keychain.
    case keychainWriteFailed

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .accessibilityPermissionDenied:
            return Strings.Errors.accessibilityPermissionDenied
        case .inputMonitoringPermissionDenied:
            return Strings.Errors.inputMonitoringPermissionDenied
        case .noTextSelected:
            return Strings.Errors.noTextSelectedMessage
        case .textCaptureTimeout:
            return Strings.Errors.textCaptureTimeout
        case .secureInputActive:
            return Strings.Errors.secureInputTitle
        case .providerNotConfigured:
            return Strings.Errors.providerNotConfigured
        case .networkUnavailable:
            return Strings.Errors.networkUnavailable
        case .apiKeyInvalid(let providerID):
            return "API key for \(providerID) is invalid"
        case .rateLimitExceeded:
            return Strings.Errors.rateLimited
        case .apiError(_, let message):
            return message
        case .ollamaNotRunning:
            return Strings.Errors.ollamaNotRunning
        case .ollamaModelNotFound(let modelName):
            return "Ollama model '\(modelName)' is not installed"
        case .streamInterrupted:
            return "Stream interrupted"
        case .oauthTokenExpired:
            return Strings.Errors.oauthExpired
        case .cannotReplaceInApp(let appName):
            return "Cannot replace text in \(appName)"
        case .keychainReadFailed:
            return "Failed to read from Keychain"
        case .keychainWriteFailed:
            return "Failed to write to Keychain"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .accessibilityPermissionDenied:
            return "Open System Settings > Privacy > Accessibility and enable Prompty."
        case .inputMonitoringPermissionDenied:
            return "Open System Settings > Privacy > Input Monitoring and enable Prompty."
        case .noTextSelected:
            return Strings.Errors.noTextSelectedDetail
        case .textCaptureTimeout:
            return "Try selecting the text again and pressing the hotkey."
        case .secureInputActive:
            return Strings.Errors.secureInputDetail
        case .providerNotConfigured(let providerID):
            return "Add an API key for \(providerID) in Settings > Providers."
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .apiKeyInvalid(let providerID):
            return "Update the API key for \(providerID) in Settings > Providers."
        case .rateLimitExceeded:
            return "Wait a moment and try again, or switch to a different provider."
        case .apiError:
            return "Check your provider settings and try again."
        case .ollamaNotRunning:
            return Strings.Errors.ollamaNotRunningDetail
        case .ollamaModelNotFound(let modelName):
            return "Run in Terminal: ollama pull \(modelName)"
        case .streamInterrupted:
            return "The connection was lost. Try again."
        case .oauthTokenExpired:
            return Strings.Errors.oauthExpiredDetail
        case .cannotReplaceInApp:
            return "The result has been copied to your clipboard. Press Cmd+V to paste."
        case .keychainReadFailed:
            return "Try restarting the app. If the problem persists, re-enter your API keys."
        case .keychainWriteFailed:
            return "Try restarting the app. Check that Keychain Access is not locked."
        }
    }
}

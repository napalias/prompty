// AppErrorTests.swift
// AITextToolTests
//
// Verifies each AppError case maps to a non-nil, human-friendly
// errorDescription and recoverySuggestion.

import Testing
@testable import AITextTool

// MARK: - AppErrorTests

struct AppErrorTests {

    // MARK: - errorDescription

    @Test
    func test_errorDescription_accessibilityPermissionDenied() {
        let err = AppError.accessibilityPermissionDenied
        #expect(err.errorDescription != nil)
        #expect(err.errorDescription == Strings.Errors.accessibilityPermissionDenied)
    }

    @Test
    func test_errorDescription_inputMonitoringPermissionDenied() {
        let err = AppError.inputMonitoringPermissionDenied
        #expect(err.errorDescription != nil)
        #expect(err.errorDescription == Strings.Errors.inputMonitoringPermissionDenied)
    }

    @Test
    func test_errorDescription_noTextSelected() {
        let err = AppError.noTextSelected
        #expect(err.errorDescription == Strings.Errors.noTextSelectedMessage)
    }

    @Test
    func test_errorDescription_textCaptureTimeout() {
        let err = AppError.textCaptureTimeout
        #expect(err.errorDescription == Strings.Errors.textCaptureTimeout)
    }

    @Test
    func test_errorDescription_secureInputActive() {
        let err = AppError.secureInputActive
        #expect(err.errorDescription == Strings.Errors.secureInputTitle)
    }

    @Test
    func test_errorDescription_providerNotConfigured() {
        let err = AppError.providerNotConfigured(providerID: "openai")
        #expect(err.errorDescription == Strings.Errors.providerNotConfigured)
    }

    @Test
    func test_errorDescription_networkUnavailable() {
        let err = AppError.networkUnavailable
        #expect(err.errorDescription == Strings.Errors.networkUnavailable)
    }

    @Test
    func test_errorDescription_apiKeyInvalid_includesProviderID() {
        let err = AppError.apiKeyInvalid(providerID: "anthropic-api")
        #expect(err.errorDescription != nil)
        #expect(err.errorDescription?.contains("anthropic-api") == true)
    }

    @Test
    func test_errorDescription_rateLimitExceeded() {
        let err = AppError.rateLimitExceeded(providerID: "openai")
        #expect(err.errorDescription == Strings.Errors.rateLimited)
    }

    @Test
    func test_errorDescription_apiError_returnsMessage() {
        let err = AppError.apiError(providerID: "openai", message: "Server error")
        #expect(err.errorDescription == "Server error")
    }

    @Test
    func test_errorDescription_ollamaNotRunning() {
        let err = AppError.ollamaNotRunning
        #expect(err.errorDescription == Strings.Errors.ollamaNotRunning)
    }

    @Test
    func test_errorDescription_ollamaModelNotFound_includesModelName() {
        let err = AppError.ollamaModelNotFound(modelName: "llama3.2")
        #expect(err.errorDescription != nil)
        #expect(err.errorDescription?.contains("llama3.2") == true)
    }

    @Test
    func test_errorDescription_streamInterrupted() {
        let err = AppError.streamInterrupted
        #expect(err.errorDescription != nil)
    }

    @Test
    func test_errorDescription_oauthTokenExpired() {
        let err = AppError.oauthTokenExpired
        #expect(err.errorDescription == Strings.Errors.oauthExpired)
    }

    @Test
    func test_errorDescription_cannotReplaceInApp_includesAppName() {
        let err = AppError.cannotReplaceInApp(appName: "Safari")
        #expect(err.errorDescription?.contains("Safari") == true)
    }

    @Test
    func test_errorDescription_keychainReadFailed() {
        let err = AppError.keychainReadFailed
        #expect(err.errorDescription != nil)
    }

    @Test
    func test_errorDescription_keychainWriteFailed() {
        let err = AppError.keychainWriteFailed
        #expect(err.errorDescription != nil)
    }

    // MARK: - recoverySuggestion

    @Test
    func test_recoverySuggestion_accessibilityPermissionDenied() {
        let err = AppError.accessibilityPermissionDenied
        #expect(err.recoverySuggestion != nil)
        #expect(err.recoverySuggestion?.contains("System Settings") == true)
    }

    @Test
    func test_recoverySuggestion_inputMonitoringPermissionDenied() {
        let err = AppError.inputMonitoringPermissionDenied
        #expect(err.recoverySuggestion?.contains("System Settings") == true)
    }

    @Test
    func test_recoverySuggestion_noTextSelected_mentionsHotkey() {
        let err = AppError.noTextSelected
        #expect(err.recoverySuggestion?.contains("hotkey") == true)
    }

    @Test
    func test_recoverySuggestion_secureInputActive_mentionsPassword() {
        let err = AppError.secureInputActive
        #expect(err.recoverySuggestion?.contains("password") == true)
    }

    @Test
    func test_recoverySuggestion_providerNotConfigured_mentionsSettings() {
        let err = AppError.providerNotConfigured(providerID: "openai")
        #expect(err.recoverySuggestion?.contains("Settings") == true)
    }

    @Test
    func test_recoverySuggestion_apiKeyInvalid_mentionsSettings() {
        let err = AppError.apiKeyInvalid(providerID: "openai")
        #expect(err.recoverySuggestion?.contains("Settings") == true)
    }

    @Test
    func test_recoverySuggestion_rateLimitExceeded_mentionsTryAgain() {
        let err = AppError.rateLimitExceeded(providerID: "openai")
        #expect(err.recoverySuggestion?.contains("try again") == true)
    }

    @Test
    func test_recoverySuggestion_ollamaNotRunning_mentionsServe() {
        let err = AppError.ollamaNotRunning
        #expect(err.recoverySuggestion?.contains("ollama serve") == true)
    }

    @Test
    func test_recoverySuggestion_ollamaModelNotFound_mentionsPull() {
        let err = AppError.ollamaModelNotFound(modelName: "llama3.2")
        #expect(err.recoverySuggestion?.contains("ollama pull llama3.2") == true)
    }

    @Test
    func test_recoverySuggestion_oauthTokenExpired_mentionsClaudeLogin() {
        let err = AppError.oauthTokenExpired
        #expect(err.recoverySuggestion?.contains("claude login") == true)
    }

    @Test
    func test_recoverySuggestion_streamInterrupted_mentionsTryAgain() {
        let err = AppError.streamInterrupted
        #expect(err.recoverySuggestion?.contains("Try again") == true)
    }

    @Test
    func test_recoverySuggestion_cannotReplaceInApp_mentionsClipboard() {
        let err = AppError.cannotReplaceInApp(appName: "Safari")
        #expect(err.recoverySuggestion?.contains("clipboard") == true)
    }

    // MARK: - All cases coverage

    @Test
    func test_allCases_haveNonNilDescriptionAndSuggestion() {
        let allCases: [AppError] = [
            .accessibilityPermissionDenied,
            .inputMonitoringPermissionDenied,
            .noTextSelected,
            .textCaptureTimeout,
            .secureInputActive,
            .providerNotConfigured(providerID: "test"),
            .networkUnavailable,
            .apiKeyInvalid(providerID: "test"),
            .rateLimitExceeded(providerID: "test"),
            .apiError(providerID: "test", message: "error"),
            .ollamaNotRunning,
            .ollamaModelNotFound(modelName: "test"),
            .streamInterrupted,
            .oauthTokenExpired,
            .cannotReplaceInApp(appName: "test"),
            .keychainReadFailed,
            .keychainWriteFailed
        ]

        for appError in allCases {
            #expect(
                appError.errorDescription != nil,
                "errorDescription is nil for \(appError)"
            )
            #expect(
                appError.recoverySuggestion != nil,
                "recoverySuggestion is nil for \(appError)"
            )
        }
    }

    // MARK: - Equatable

    @Test
    func test_equatable_sameCases() {
        #expect(AppError.ollamaNotRunning == AppError.ollamaNotRunning)
        #expect(AppError.ollamaNotRunning != AppError.networkUnavailable)
    }

    @Test
    func test_equatable_associatedValues() {
        #expect(
            AppError.apiKeyInvalid(providerID: "a")
                == AppError.apiKeyInvalid(providerID: "a")
        )
        #expect(
            AppError.apiKeyInvalid(providerID: "a")
                != AppError.apiKeyInvalid(providerID: "b")
        )
    }
}

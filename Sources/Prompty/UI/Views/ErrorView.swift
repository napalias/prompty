// ErrorView.swift
// Prompty
//
// Friendly error display with recovery suggestions and action buttons.
// Never shows raw error text -- always uses AppError.errorDescription
// and recoverySuggestion for human-friendly messages.

import SwiftUI

// MARK: - ErrorView

struct ErrorView: View {
    let error: AppError
    var onRetry: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            errorIcon
            errorMessage
            recoveryText
            actionButtons
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Icon

    private var errorIcon: some View {
        Image(systemName: iconName)
            .font(.system(size: 36))
            .foregroundStyle(iconColor)
            .accessibilityHidden(true)
    }

    // MARK: - Message

    private var errorMessage: some View {
        Text(error.errorDescription ?? Strings.Errors.streamInterrupted)
            .font(.headline)
            .multilineTextAlignment(.center)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Recovery

    @ViewBuilder
    private var recoveryText: some View {
        if let suggestion = error.recoverySuggestion {
            Text(suggestion)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 12) {
            switch error {
            case .accessibilityPermissionDenied,
                 .inputMonitoringPermissionDenied:
                openSystemSettingsButton

            case .providerNotConfigured:
                openSettingsButton

            case .apiKeyInvalid:
                checkApiKeyButton

            case .rateLimitExceeded:
                retryButton

            case .ollamaNotRunning:
                ollamaHintView

            case .ollamaModelNotFound(let modelName):
                copyCommandButton(
                    command: "ollama pull \(modelName)"
                )

            case .networkUnavailable, .streamInterrupted:
                retryButton

            case .oauthTokenExpired:
                oauthReauthView

            case .secureInputActive:
                // No action button -- user must click away
                // from the password field themselves.
                EmptyView()

            case .noTextSelected,
                 .textCaptureTimeout,
                 .apiError,
                 .cannotReplaceInApp,
                 .keychainReadFailed,
                 .keychainWriteFailed:
                dismissButton
            }
        }
    }

    // MARK: - Button Builders

    private var openSystemSettingsButton: some View {
        Button(Strings.Errors.openSystemSettings) {
            openPrivacySettings()
        }
        .buttonStyle(.borderedProminent)
    }

    private var openSettingsButton: some View {
        Button(Strings.Errors.openSettings) {
            onOpenSettings?()
        }
        .buttonStyle(.borderedProminent)
    }

    private var checkApiKeyButton: some View {
        Button(Strings.Errors.checkApiKey) {
            onOpenSettings?()
        }
        .buttonStyle(.borderedProminent)
    }

    private var retryButton: some View {
        Button(Strings.Errors.retry) {
            onRetry?()
        }
        .buttonStyle(.borderedProminent)
    }

    private var ollamaHintView: some View {
        VStack(spacing: 8) {
            Text(Strings.Errors.ollamaServeCommand)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Button(Strings.Errors.copyCommand) {
                copyToClipboard(Strings.Errors.ollamaServeCommand)
            }
            .buttonStyle(.bordered)
        }
    }

    private func copyCommandButton(
        command: String
    ) -> some View {
        VStack(spacing: 8) {
            Text(command)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Button(Strings.Errors.copyCommand) {
                copyToClipboard(command)
            }
            .buttonStyle(.bordered)
        }
    }

    private var oauthReauthView: some View {
        VStack(spacing: 8) {
            Text(Strings.Errors.claudeLoginCommand)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Button(Strings.Errors.copyCommand) {
                copyToClipboard(Strings.Errors.claudeLoginCommand)
            }
            .buttonStyle(.bordered)
        }
    }

    private var dismissButton: some View {
        Button(Strings.ActionBar.dismiss) {
            onDismiss?()
        }
        .buttonStyle(.bordered)
    }

    // MARK: - Helpers

    private var iconName: String {
        switch error {
        case .secureInputActive:
            return "lock.fill"
        case .accessibilityPermissionDenied,
             .inputMonitoringPermissionDenied:
            return "lock.shield"
        case .networkUnavailable:
            return "wifi.slash"
        case .ollamaNotRunning, .ollamaModelNotFound:
            return "desktopcomputer"
        case .oauthTokenExpired, .apiKeyInvalid:
            return "key.slash"
        case .rateLimitExceeded:
            return "clock.arrow.circlepath"
        case .providerNotConfigured:
            return "gear.badge.xmark"
        case .streamInterrupted:
            return "bolt.slash"
        case .noTextSelected:
            return "selection.pin.in.out"
        default:
            return "exclamationmark.triangle"
        }
    }

    private var iconColor: Color {
        switch error {
        case .secureInputActive, .rateLimitExceeded:
            return .orange
        case .networkUnavailable:
            return .gray
        case .accessibilityPermissionDenied,
             .inputMonitoringPermissionDenied:
            return .red
        default:
            return .red
        }
    }

    private func openPrivacySettings() {
        let pane: String
        switch error {
        case .inputMonitoringPermissionDenied:
            pane = "Privacy_ListenEvent"
        default:
            pane = "Privacy_Accessibility"
        }
        if let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?\(pane)"
        ) {
            NSWorkspace.shared.open(url)
        }
    }

    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

// MARK: - Preview

#Preview("API Key Invalid") {
    ErrorView(
        error: PreviewData.sampleError,
        onRetry: {},
        onOpenSettings: {},
        onDismiss: {}
    )
    .frame(width: 480)
}

#Preview("Network Unavailable") {
    ErrorView(
        error: .networkUnavailable,
        onRetry: {},
        onDismiss: {}
    )
    .frame(width: 480)
}

#Preview("Secure Input") {
    ErrorView(
        error: .secureInputActive,
        onDismiss: {}
    )
    .frame(width: 480)
}

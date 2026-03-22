// ProvidersSettingsView.swift
// AITextTool
//
// API key fields for Anthropic, OpenAI. Model selection per provider.
// Ollama URL + model config. OAuth status display.
// Keys saved to KeychainService. Test connection button.

import SwiftUI
import os

// MARK: - Keychain key constants

private enum KeychainKeys {
    static let anthropicAPIKey = "api_key_anthropic"
    static let openaiAPIKey = "api_key_openai"
}

// MARK: - ProvidersSettingsView

struct ProvidersSettingsView: View {
    let settingsRepo: SettingsRepositoryProtocol
    let keychainService: KeychainServiceProtocol

    @State private var activeProviderID: String = "anthropic-api"
    @State private var anthropicKey: String = ""
    @State private var anthropicModel: String = ModelConstants.Anthropic.defaultModel
    @State private var openaiKey: String = ""
    @State private var openaiModel: String = ModelConstants.OpenAI.defaultModel
    @State private var openaiBaseURL: String = ""
    @State private var ollamaURL: String = ""
    @State private var ollamaModel: String = "llama3.2"
    @State private var connectionStatus: ConnectionStatus = .idle

    var body: some View {
        Form {
            activeProviderSection
            anthropicSection
            openaiSection
            ollamaSection
        }
        .formStyle(.grouped)
        .onAppear { loadAll() }
    }

    // MARK: - Active Provider

    private var activeProviderSection: some View {
        Section("Active Provider") {
            Picker("Provider", selection: $activeProviderID) {
                Text("Claude (API Key)").tag("anthropic-api")
                Text("ChatGPT (API Key)").tag("openai")
                Text("Ollama (Local)").tag("ollama")
            }
            .onChange(of: activeProviderID) { _, newValue in
                settingsRepo.update { $0.activeProviderID = newValue }
            }
        }
    }

    // MARK: - Anthropic

    private var anthropicSection: some View {
        Section("Claude (API Key)") {
            SecureField(
                Strings.Settings.anthropicApiKey,
                text: $anthropicKey
            )
            .accessibilityLabel(Strings.Settings.anthropicApiKey)
            .onChange(of: anthropicKey) { _, newValue in
                saveKeyToKeychain(
                    key: KeychainKeys.anthropicAPIKey,
                    value: newValue
                )
            }

            Picker(Strings.Settings.model, selection: $anthropicModel) {
                ForEach(ModelConstants.Anthropic.availableModels, id: \.self) {
                    Text($0).tag($0)
                }
            }
            .onChange(of: anthropicModel) { _, newValue in
                settingsRepo.update {
                    $0.selectedModelPerProvider["anthropic-api"] = newValue
                }
            }
        }
    }

    // MARK: - OpenAI

    private var openaiSection: some View {
        Section("ChatGPT (API Key)") {
            SecureField(
                Strings.Settings.openaiApiKey,
                text: $openaiKey
            )
            .accessibilityLabel(Strings.Settings.openaiApiKey)
            .onChange(of: openaiKey) { _, newValue in
                saveKeyToKeychain(
                    key: KeychainKeys.openaiAPIKey,
                    value: newValue
                )
            }

            TextField(
                Strings.Settings.customBaseURL,
                text: $openaiBaseURL,
                prompt: Text(Strings.Settings.baseURLPlaceholder)
            )
            .accessibilityLabel(Strings.Settings.customBaseURL)
            .onChange(of: openaiBaseURL) { _, newValue in
                settingsRepo.update {
                    var config = $0.providerConfigs["openai"]
                        ?? ProviderConfig(providerID: "openai")
                    config.customBaseURL = newValue.isEmpty ? nil : newValue
                    $0.providerConfigs["openai"] = config
                }
            }

            quickFillButtons

            Picker(Strings.Settings.model, selection: $openaiModel) {
                ForEach(ModelConstants.OpenAI.availableModels, id: \.self) {
                    Text($0).tag($0)
                }
            }
            .onChange(of: openaiModel) { _, newValue in
                settingsRepo.update {
                    $0.selectedModelPerProvider["openai"] = newValue
                }
            }
        }
    }

    private var quickFillButtons: some View {
        HStack {
            Text(Strings.Settings.quickFill)
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("OpenAI") {
                openaiBaseURL = "https://api.openai.com/v1"
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            Button("Groq") {
                openaiBaseURL = "https://api.groq.com/openai/v1"
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            Button("LM Studio") {
                openaiBaseURL = "http://localhost:1234/v1"
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    // MARK: - Ollama

    private var ollamaSection: some View {
        Section("Ollama (Local)") {
            TextField(
                Strings.Settings.ollamaBaseURL,
                text: $ollamaURL,
                prompt: Text(Strings.Settings.ollamaBaseURLDefault)
            )
            .accessibilityLabel(Strings.Settings.ollamaBaseURL)
            .onChange(of: ollamaURL) { _, newValue in
                settingsRepo.update {
                    var config = $0.providerConfigs["ollama"]
                        ?? ProviderConfig(providerID: "ollama")
                    config.customBaseURL = newValue.isEmpty ? nil : newValue
                    $0.providerConfigs["ollama"] = config
                }
            }

            TextField(
                Strings.Settings.model,
                text: $ollamaModel,
                prompt: Text("llama3.2")
            )
            .onChange(of: ollamaModel) { _, newValue in
                settingsRepo.update {
                    $0.selectedModelPerProvider["ollama"] = newValue
                }
            }

            testConnectionButton
        }
    }

    // MARK: - Test Connection

    private var testConnectionButton: some View {
        HStack {
            Button(action: testOllamaConnection) {
                HStack(spacing: 4) {
                    if connectionStatus == .testing {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(
                        connectionStatus == .testing
                            ? Strings.Settings.testing
                            : Strings.Settings.testConnection
                    )
                }
            }
            .disabled(connectionStatus == .testing)

            if connectionStatus == .success {
                Label(
                    Strings.Settings.connectionSuccess,
                    systemImage: "checkmark.circle.fill"
                )
                .foregroundStyle(.green)
                .font(.caption)
            } else if connectionStatus == .failed {
                Label(
                    Strings.Settings.connectionFailed,
                    systemImage: "xmark.circle.fill"
                )
                .foregroundStyle(.red)
                .font(.caption)
            }
        }
    }

    // MARK: - Private

    private func loadAll() {
        let current = settingsRepo.settings
        activeProviderID = current.activeProviderID
        anthropicModel = current.selectedModelPerProvider["anthropic-api"]
            ?? ModelConstants.Anthropic.defaultModel
        openaiModel = current.selectedModelPerProvider["openai"]
            ?? ModelConstants.OpenAI.defaultModel
        openaiBaseURL = current.providerConfigs["openai"]?.customBaseURL ?? ""
        ollamaURL = current.providerConfigs["ollama"]?.customBaseURL ?? ""
        ollamaModel = current.selectedModelPerProvider["ollama"] ?? "llama3.2"

        if let data = try? keychainService.read(
            key: KeychainKeys.anthropicAPIKey
        ) {
            anthropicKey = String(data: data, encoding: .utf8) ?? ""
        }
        if let data = try? keychainService.read(
            key: KeychainKeys.openaiAPIKey
        ) {
            openaiKey = String(data: data, encoding: .utf8) ?? ""
        }
    }

    private func saveKeyToKeychain(key: String, value: String) {
        do {
            if value.isEmpty {
                try keychainService.delete(key: key)
            } else if let data = value.data(using: .utf8) {
                try keychainService.save(key: key, data: data)
            }
        } catch {
            Logger.settings.error(
                "Keychain save failed for \(key): \(error.localizedDescription)"
            )
        }
    }

    private func testOllamaConnection() {
        connectionStatus = .testing
        let baseURL = ollamaURL.isEmpty
            ? Strings.Settings.ollamaBaseURLDefault
            : ollamaURL
        guard let url = URL(string: "\(baseURL)/api/tags") else {
            connectionStatus = .failed
            return
        }
        Task {
            do {
                let (_, response) = try await URLSession.shared.data(from: url)
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200
                {
                    connectionStatus = .success
                } else {
                    connectionStatus = .failed
                }
            } catch {
                connectionStatus = .failed
            }
        }
    }
}

// MARK: - ConnectionStatus

private enum ConnectionStatus {
    case idle
    case testing
    case success
    case failed
}

// MARK: - Preview

#Preview {
    ProvidersSettingsView(
        settingsRepo: PreviewProviderSettingsRepo(),
        keychainService: PreviewProviderKeychainSvc()
    )
    .frame(width: 480)
}

private final class PreviewProviderSettingsRepo: SettingsRepositoryProtocol,
    @unchecked Sendable
{
    private var current = AppSettings()
    var settings: AppSettings { current }
    func update(_ transform: (inout AppSettings) -> Void) {
        transform(&current)
    }
    func reset() { current = AppSettings() }
}

private final class PreviewProviderKeychainSvc: KeychainServiceProtocol,
    @unchecked Sendable
{
    private var store: [String: Data] = [:]
    func save(key: String, data: Data) throws { store[key] = data }
    func read(key: String) throws -> Data? { store[key] }
    func delete(key: String) throws { store[key] = nil }
}

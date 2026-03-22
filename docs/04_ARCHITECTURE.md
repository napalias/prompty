# 04 — Architecture

## Design Principles

1. **DRY** — every piece of logic lives in exactly one place
2. **Single Responsibility** — each class/struct does one thing
3. **Protocol-first** — depend on protocols, not concrete types (enables mocking for tests)
4. **Value types first** — prefer `struct` over `class`; use `class` only when identity/reference semantics are needed
5. **Unidirectional data flow** — `AppState` is the single source of truth; views observe, actions mutate
6. **Fail loudly in debug, gracefully in release** — `assert()` in logic, user-facing errors in UI

---

## Pattern Choices

| Problem | Pattern Used | Reason |
|---------|-------------|--------|
| Shared mutable app state | `@Observable` singleton `AppState` | SwiftUI native, simple for single-user |
| AI provider abstraction | Protocol + concrete impls | Easy to add providers, easy to mock |
| Async streaming | `AsyncThrowingStream` | Native Swift, composes with `for await` |
| Persistence | Repository pattern | Decouples storage from logic |
| Settings / secrets | `SettingsRepository` + `KeychainService` | Separation of concerns |
| Prompt management | Repository + Value model | CRUD in one place |
| Error handling | Typed `AppError` enum | Exhaustive, no stringly-typed errors |
| Side effects | `async` functions, no Combine | Simpler, more readable |

---

## Full Folder Structure

```
AITextTool/
├── AITextTool.xcodeproj/
├── AITextTool/
│   ├── App/
│   │   ├── AITextToolApp.swift          # @main entry, AppDelegate setup
│   │   ├── AppDelegate.swift            # NSApplicationDelegate
│   │   └── AppState.swift               # @Observable global state (single source of truth)
│   │
│   ├── Core/
│   │   ├── Errors/
│   │   │   └── AppError.swift           # Typed error enum for the whole app
│   │   ├── Extensions/
│   │   │   ├── String+Truncate.swift
│   │   │   └── NSPasteboard+Safe.swift
│   │   └── Utilities/
│   │       ├── Logger.swift             # Thin os.Logger wrapper (subsystem + categories defined here)
│       ├── Strings.swift            # ALL user-facing string constants — no hardcoded strings in views
│       └── PreviewData.swift        # Static mock data for SwiftUI #Preview blocks
│   │
│   ├── Hotkey/
│   │   ├── HotkeyManager.swift          # Protocol + CGEventTap implementation
│   │   └── HotkeyManagerProtocol.swift  # Protocol for testing
│   │
│   ├── TextCapture/
│   │   ├── TextCaptureService.swift           # Orchestrates AX + clipboard fallback
│   │   ├── TextCaptureServiceProtocol.swift
│   │   ├── AccessibilityReader.swift          # AXUIElement reading
│   │   ├── ClipboardFallbackReader.swift      # Simulates ⌘C, reads clipboard
│   │   └── PermissionChecker.swift            # AXIsProcessTrusted check
│   │
│   ├── TextReplace/
│   │   ├── TextReplaceService.swift           # Orchestrates AX + clipboard fallback
│   │   ├── TextReplaceServiceProtocol.swift
│   │   ├── AccessibilityWriter.swift          # AXUIElement writing
│   │   └── ClipboardPasteWriter.swift         # ⌘V simulation
│   │
│   ├── AI/
│   │   ├── AIProviderProtocol.swift           # Core protocol all providers implement
│   │   ├── AIProviderManager.swift            # Selects active provider, delegates
│   │   ├── Models/
│   │   │   ├── AIMessage.swift                # role + content value type
│   │   │   ├── AIRequest.swift                # prompt + text + history
│   │   │   └── AIResponse.swift               # streaming token or final result
│   │   ├── Providers/
│   │   │   ├── AnthropicProvider.swift        # API key mode
│   │   │   ├── AnthropicOAuthProvider.swift   # Claude Code OAuth mode
│   │   │   ├── OpenAIProvider.swift           # API key mode
│   │   │   └── OllamaProvider.swift           # Local REST
│   │   └── Streaming/
│   │       └── SSEParser.swift                # Server-Sent Events line parser
│   │
│   ├── Prompts/
│   │   ├── Models/
│   │   │   ├── Prompt.swift                   # Value type: id, title, icon, template, resultMode
│   │   │   └── ResultMode.swift               # Enum: replace, copy, diff, continueChat
│   │   ├── BuiltInPrompts.swift               # Static default library
│   │   ├── PromptRepository.swift             # CRUD + persistence
│   │   └── PromptRepositoryProtocol.swift
│   │
│   ├── Settings/
│   │   ├── Models/
│   │   │   └── AppSettings.swift              # Codable settings value type
│   │   ├── SettingsRepository.swift           # Reads/writes UserDefaults
│   │   ├── SettingsRepositoryProtocol.swift
│   │   ├── KeychainService.swift              # Secure API key storage
│   │   └── KeychainServiceProtocol.swift
│   │
│   ├── UI/
│   │   ├── MenuBar/
│   │   │   └── MenuBarController.swift        # NSStatusItem + menu
│   │   ├── Panel/
│   │   │   ├── FloatingPanel.swift            # NSPanel subclass
│   │   │   └── FloatingPanelController.swift  # Manages show/hide/position
│   │   ├── Views/
│   │   │   ├── MainPanelView.swift            # Root view, routes to sub-views
│   │   │   ├── PromptPickerView.swift         # Scrollable prompt list
│   │   │   ├── TextInputView.swift            # Free-text prompt input
│   │   │   ├── StreamingResultView.swift      # Live token display + action bar
│   │   │   ├── DiffView.swift                 # Side-by-side old/new
│   │   │   ├── ContinueChatView.swift         # Multi-turn follow-up
│   │   │   ├── ActionBarView.swift            # Enter/⌘Enter/D keyboard hints
│   │   │   ├── ErrorView.swift                # Friendly error display
│   │   │   ├── ToastPanel.swift               # Lightweight 2s auto-dismiss toast (no-text-selected)
│   │   │   └── EditBeforeReplaceView.swift    # Editable TextEditor before confirming replace
│   │   └── Settings/
│   │       ├── SettingsWindowController.swift
│   │       ├── SettingsView.swift             # Tab container
│   │       ├── ProvidersSettingsView.swift    # API keys, OAuth status
│   │       ├── PromptsSettingsView.swift      # CRUD for custom prompts
│   │       └── GeneralSettingsView.swift      # Hotkey, launch at login
│   │
│   └── Sidecar/                              # Bundled Node.js process for Claude OAuth
│       ├── sidecar.js                         # Claude Agent SDK wrapper
│       └── package.json
│
└── AITextToolTests/
    ├── Hotkey/
    │   └── HotkeyManagerTests.swift
    ├── TextCapture/
    │   ├── AccessibilityReaderTests.swift
    │   ├── ClipboardFallbackReaderTests.swift
    │   └── TextCaptureServiceTests.swift
    ├── AI/
    │   ├── SSEParserTests.swift
    │   ├── AnthropicProviderTests.swift
    │   ├── OpenAIProviderTests.swift
    │   ├── OllamaProviderTests.swift
    │   └── AIProviderManagerTests.swift
    ├── Prompts/
    │   ├── PromptRepositoryTests.swift
    │   └── BuiltInPromptsTests.swift
    ├── Settings/
    │   ├── SettingsRepositoryTests.swift
    │   └── KeychainServiceTests.swift
    ├── TextReplace/
    │   └── TextReplaceServiceTests.swift
    ├── Integration/
    │   └── HotkeyToCaptureToStreamToReplaceTests.swift  # Full flow integration test
    └── Mocks/
        ├── MockHotkeyManager.swift
        ├── MockTextCaptureService.swift
        ├── MockTextReplaceService.swift
        ├── MockAIProvider.swift
        ├── MockPromptRepository.swift
        └── MockSettingsRepository.swift
```

---

## AppState — Single Source of Truth

```swift
// AppState.swift
// IMPORTANT: All AppState mutations MUST happen on @MainActor.
// AppState is bound to the main actor — accessing it from background Tasks
// requires `await MainActor.run { }` or calling a @MainActor-marked method.
@Observable
@MainActor
final class AppState {
    // MARK: - Text
    var capturedText: String = ""
    var selectedPrompt: Prompt? = nil
    var customPromptInput: String = ""
    var capturedTextWasTruncated: Bool = false
    var capturedTextOriginalLength: Int = 0

    // MARK: - AI Response
    var streamingTokens: String = ""
    var isStreaming: Bool = false
    var streamingError: AppError? = nil
    var lastResponseTokens: TokenUsage? = nil
    private(set) var streamingTask: Task<Void, Never>? = nil

    // MARK: - Panel
    var panelMode: PanelMode = .promptPicker
    var panelMode_sessionRenderOverride: ResultRenderMode? = nil
    var isVisible: Bool = false

    // MARK: - Conversation (continue-chat + history)
    var conversationHistory: [AIMessage] = []
    var currentSession: ConversationSession? = nil

    // MARK: - Mutations (all @MainActor — called from UI or Task { @MainActor in })
    func startStreaming(task: Task<Void, Never>) { streamingTask = task; isStreaming = true }
    func cancelStreaming() { streamingTask?.cancel(); streamingTask = nil; isStreaming = false }
    func reset(capturedText: String) { /* resets all transient state, see 18B */ }
}

enum PanelMode {
    case promptPicker       // Initial state: list of prompts
    case customInput        // Free text input
    case streaming          // Showing streaming result
    case diff               // Diff view
    case continueChat       // Follow-up prompting
    case error              // Error state
}
```

---

## AIProviderProtocol — Core Abstraction

```swift
// AIProviderProtocol.swift
protocol AIProvider: Sendable {
    var id: String { get }           // "anthropic-api", "anthropic-oauth", "openai", "ollama"
    var displayName: String { get }  // "Claude (API Key)"
    var isConfigured: Bool { get }   // Returns false if required config is missing

    func stream(
        request: AIRequest
    ) -> AsyncThrowingStream<String, Error>
}
```

---

## Error Handling

```swift
// AppError.swift
enum AppError: LocalizedError, Equatable {
    // Text capture
    case accessibilityPermissionDenied
    case noTextSelected
    case textCaptureTimeout

    // AI providers
    case providerNotConfigured(providerID: String)
    case networkUnavailable
    case apiKeyInvalid(providerID: String)
    case rateLimitExceeded(providerID: String)
    case apiError(providerID: String, message: String)
    case ollamaNotRunning
    case streamInterrupted

    // Text replace
    case cannotReplaceInApp(appName: String)

    // Settings
    case keychainReadFailed
    case keychainWriteFailed

    var errorDescription: String? { /* human-readable */ }
    var recoverySuggestion: String? { /* actionable hint */ }
}

// Complete AppError case list (agents must not add new cases without spec approval):
// .accessibilityPermissionDenied
// .inputMonitoringPermissionDenied    ← CGEventTap permission
// .noTextSelected
// .textCaptureTimeout
// .secureInputActive                  ← 16B
// .providerNotConfigured(providerID:)
// .networkUnavailable
// .apiKeyInvalid(providerID:)
// .rateLimitExceeded(providerID:)
// .apiError(providerID:, message:)
// .ollamaNotRunning
// .ollamaModelNotFound(modelName:)    ← 18I
// .streamInterrupted
// .oauthTokenExpired                  ← 19D
// .cannotReplaceInApp(appName:)
// .keychainReadFailed
// .keychainWriteFailed
```

---

## Dependency Injection

All services are injected via initialiser. Never use singletons directly in classes that need testing.

```swift
// ✅ Correct
final class FloatingPanelController {
    private let textCapture: TextCaptureServiceProtocol
    private let aiManager: AIProviderManagerProtocol
    private let promptRepo: PromptRepositoryProtocol
    private let state: AppState

    init(
        textCapture: TextCaptureServiceProtocol,
        aiManager: AIProviderManagerProtocol,
        promptRepo: PromptRepositoryProtocol,
        state: AppState
    ) { ... }
}

// ❌ Wrong
final class FloatingPanelController {
    private let textCapture = TextCaptureService()  // untestable
}
```

---

## Data Flow Diagram

```
Hotkey fires
    │
    ▼
HotkeyManager ──► notifies ──► AppDelegate
                                    │
                                    ▼
                           TextCaptureService.capture()
                                    │
                             ┌──────┴──────┐
                             │             │
                        AX succeeds    AX fails
                             │             │
                             │         Clipboard
                             │         fallback
                             └──────┬──────┘
                                    │
                                    ▼
                         AppState.capturedText = text
                         AppState.panelMode = .promptPicker
                         AppState.isVisible = true
                                    │
                                    ▼
                         FloatingPanel shows
                         User picks prompt
                                    │
                                    ▼
                         AIProviderManager.stream(request)
                                    │
                             ┌──────┴──────┐
                             │  tokens     │  error
                             ▼             ▼
                  AppState.streaming   AppState.streamingError
                  Tokens += token      panelMode = .error
                                    │
                         User presses action key
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
                  Enter          ⌘Enter            D
                    │               │               │
               TextReplace     Clipboard        DiffView
               Service         copy             shows
```

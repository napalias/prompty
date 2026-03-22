# 18 — Remaining Critical Gaps

---

## 18A — Node.js Bundling for OAuth Sidecar

### Problem
The Claude OAuth sidecar requires Node.js. macOS does not ship with Node.js.
Requiring the user to install it breaks the "zero friction" goal.

### Decision: Bundle a portable Node binary inside the .app

```
AITextTool.app/
└── Contents/
    ├── MacOS/
    │   └── AITextTool          ← main binary
    └── Resources/
        └── Sidecar/
            ├── node            ← portable Node.js binary (no install needed)
            ├── sidecar.js
            └── node_modules/   ← pre-bundled npm deps
```

### How to produce the portable binary

```bash
# Download the official Node.js macOS binary (no installer)
# https://nodejs.org/en/download — choose "macOS Binary (.tar.gz)"
# Strip to just the `node` executable — it's self-contained, ~55MB
curl -O https://nodejs.org/dist/v20.12.0/node-v20.12.0-darwin-arm64.tar.gz
tar xzf node-v20.12.0-darwin-arm64.tar.gz
cp node-v20.12.0-darwin-arm64/bin/node AITextTool/Sidecar/node

# Install npm deps into the Sidecar folder
cd AITextTool/Sidecar
npm install --omit=dev  # produces node_modules/
```

### Build phase in Xcode
Add a "Run Script" build phase BEFORE "Copy Bundle Resources":
```bash
# Ensure Sidecar/node_modules is up to date
cd "$SRCROOT/AITextTool/Sidecar"
npm install --omit=dev --prefer-offline
```

### SidecarManager — use bundled node path
```swift
// SidecarManager.swift
private var nodePath: URL {
    Bundle.main.url(forResource: "node", withExtension: nil,
                    subdirectory: "Sidecar")!
}
private var sidecarScriptPath: URL {
    Bundle.main.url(forResource: "sidecar", withExtension: "js",
                    subdirectory: "Sidecar")!
}

// When spawning:
let process = Process()
process.executableURL = nodePath
process.arguments = [sidecarScriptPath.path]
```

### isConfigured check for OAuth provider
Instead of checking if `claude` CLI is in PATH, check if the OAuth token
exists in the macOS Keychain (placed there by `claude login`):
```swift
var isConfigured: Bool {
    // Claude Code CLI stores token under this service
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "claude-code",
        kSecReturnData as String: false
    ]
    return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
}
```

### .gitignore additions
```
AITextTool/Sidecar/node
AITextTool/Sidecar/node_modules/
```
These are large binaries — never commit them. The Xcode build phase regenerates them.

---

## 18B — Hotkey Fires While Panel Is Already Open

### Defined Behaviour
If the hotkey fires while the panel is already visible, the action depends on state:

| Current panel state | Hotkey behaviour |
|--------------------|-----------------|
| `promptPicker` (no streaming) | Capture new text, reset panel with new text |
| `streaming` (AI responding) | Cancel stream, capture new text, reset |
| `diff` or `continueChat` | Dismiss panel fully, then re-open with new text |
| `error` | Dismiss error, capture new text, re-open |

### Implementation
```swift
// AppDelegate or FloatingPanelController — onHotkeyFired handler
func handleHotkeyFired() async {
    if state.isStreaming {
        state.cancelStreaming()
    }

    let text: String
    do {
        text = try await textCapture.capture()
    } catch {
        state.streamingError = error as? AppError
        state.panelMode = .error
        panelController.show(near: NSEvent.mouseLocation)
        return
    }

    // Always reset to fresh state regardless of previous mode
    state.reset(capturedText: text)
    panelController.show(near: NSEvent.mouseLocation)
}
```

### AppState.reset()
```swift
// AppState.swift
func reset(capturedText: String) {
    self.capturedText = capturedText
    self.capturedTextWasTruncated = false
    self.streamingTokens = ""
    self.isStreaming = false
    self.streamingError = nil
    self.panelMode = .promptPicker
    self.conversationHistory = []
    self.selectedPrompt = nil
    self.customPromptInput = ""
    // Note: currentSession is ended by endSession() separately
}
```

---

## 18C — Source App Closes While Panel Is Open

### Problem
The panel may be open while the user's document is closing or the app is quitting.
When `TextReplaceService.replace()` is called, the `AXUIElement` reference is stale
and returns `kAXErrorInvalidUIElement`.

### Handling
This is already covered by the existing fallback chain in `TextReplaceService`:
- AX writer returns `kAXErrorInvalidUIElement` → throw `AppError.cannotReplaceInApp`
- Service catches it → falls back to clipboard paste writer
- Clipboard paste writer simulates ⌘V → the app that IS frontmost receives it

If no app is frontmost or paste also fails, show `ErrorView` with:
```
"Could not replace text — the source app may have closed.
 The result is in your clipboard (⌘V to paste)."
```
And automatically copy the result to clipboard as a safety net.

### Safety Net — always copy on replace failure
```swift
// TextReplaceService.replace(with:)
do {
    try await primaryReplace(text: text)
} catch AppError.cannotReplaceInApp {
    // Automatic clipboard safety net
    copyToClipboard(text)
    throw AppError.cannotReplaceInApp(appName: "Unknown — copied to clipboard")
}
```

---

## 18D — First-Launch Permissions Wizard

### Why Required
Without Accessibility and Input Monitoring permissions, the app is completely
non-functional. A first-launch guide is not optional — it is the difference
between a working app and a confusing broken one.

### OnboardingView
Show this window ONCE on first launch (check `UserDefaults["hasCompletedOnboarding"]`).
It is a modal window, not a panel — it blocks the rest of the app until complete.

```
┌─────────────────────────────────────────────────────────────┐
│                   Welcome to AITextTool                     │
│                                                             │
│  ──────────────────────────────────────────────────────     │
│                                                             │
│  Step 1 of 2 — Accessibility Access                        │
│                                                             │
│  [lock.fill icon]                                           │
│                                                             │
│  AITextTool needs Accessibility access to read              │
│  selected text from other apps.                             │
│                                                             │
│  1. Click "Open System Settings" below                      │
│  2. Find AITextTool in the list                             │
│  3. Toggle it ON                                            │
│  4. Return here                                             │
│                                                             │
│  Status: ● Not granted    (refreshes every 2 seconds)       │
│                                                             │
│  [Open System Settings]            [Skip — I'll do later]   │
└─────────────────────────────────────────────────────────────┘
```

Step 2 is identical but for Input Monitoring.
After both are granted (or skipped), show a "You're ready!" screen,
then dismiss and start normal operation.

### Implementation
```swift
// OnboardingViewModel.swift
@Observable
final class OnboardingViewModel {
    var accessibilityGranted: Bool = false
    var inputMonitoringGranted: Bool = false
    var currentStep: Int = 1

    private var timer: Timer?

    func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkPermissions()
        }
    }

    private func checkPermissions() {
        accessibilityGranted = AXIsProcessTrusted()
        // Input Monitoring: use IOHIDCheckAccess
        inputMonitoringGranted = IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted
        if accessibilityGranted && inputMonitoringGranted {
            timer?.invalidate()
        }
    }
}
```

---

## 18E — Undo After Replace

### Decision
Rely entirely on the source app's native undo stack.

When `TextReplaceService` uses the AX writer (`kAXSelectedTextAttribute` setter),
most native macOS apps register this as an undoable action in their own undo manager.
When using the clipboard paste fallback (`⌘V`), this is also registered by the app.

**Do NOT implement a custom undo mechanism.** It would conflict with the source
app's own undo stack and create confusing behaviour.

**Do document this for the user:**
Add a tooltip or help text in the action bar:
```
"⌘Z in the source app to undo"
```

---

## 18F — Prompt Validation Rules

`PromptRepository.add()` and `PromptRepository.update()` must validate:

```swift
enum PromptValidationError: Error, LocalizedError {
    case titleEmpty
    case titleTooLong           // > 50 chars
    case templateEmpty
    case templateTooLong        // > 2000 chars
    case iconNotSFSymbol        // validate with UIImage(systemName:) != nil check

    var errorDescription: String? { /* human-readable */ }
}

func validate(_ prompt: Prompt) throws {
    guard !prompt.title.trimmingCharacters(in: .whitespaces).isEmpty
          else { throw PromptValidationError.titleEmpty }
    guard prompt.title.count <= 50
          else { throw PromptValidationError.titleTooLong }
    guard !prompt.template.trimmingCharacters(in: .whitespaces).isEmpty
          else { throw PromptValidationError.templateEmpty }
    guard prompt.template.count <= 2_000
          else { throw PromptValidationError.templateTooLong }
    guard NSImage(systemSymbolName: prompt.icon, accessibilityDescription: nil) != nil
          else { throw PromptValidationError.iconNotSFSymbol }
}
```

If the template contains neither `{text}` nor `{input}`, show a **warning** (not error):
```
"⚠️ Prompt template has no {text} placeholder.
 Selected text will be appended at the end."
```

---

## 18G — SwiftLint Configuration

Create `.swiftlint.yml` at repo root. Agents must NOT modify this file.

```yaml
# .swiftlint.yml
included:
  - AITextTool
excluded:
  - AITextTool/Sidecar
  - AITextToolTests/Mocks

opt_in_rules:
  - force_unwrapping
  - force_try
  - implicitly_unwrapped_optional
  - discouraged_optional_boolean
  - empty_count
  - first_where
  - sorted_imports
  - closure_spacing
  - operator_usage_whitespace

rules:
  file_length:
    warning: 200
    error: 250
    ignore_comment_only_lines: true
  function_body_length:
    warning: 35
    error: 40
  type_body_length:
    warning: 200
    error: 300
  line_length:
    warning: 120
    error: 150
    ignores_urls: true
    ignores_comments: true
  cyclomatic_complexity:
    warning: 8
    error: 12
  nesting:
    type_level:
      warning: 2
  identifier_name:
    min_length: 2
    excluded: [id, x, y]

custom_rules:
  no_print:
    name: "No print statements"
    regex: '^\s*print\('
    message: "Use Logger.swift instead of print(). See 04_ARCHITECTURE.md"
    severity: error
```

---

## 18H — Prompt Import/Export Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema",
  "title": "AITextTool Prompt Export",
  "type": "object",
  "required": ["version", "exportedAt", "prompts"],
  "properties": {
    "version": { "type": "integer", "enum": [1] },
    "exportedAt": { "type": "string", "format": "date-time" },
    "prompts": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["title", "icon", "template", "resultMode"],
        "properties": {
          "title":        { "type": "string", "maxLength": 50 },
          "icon":         { "type": "string" },
          "template":     { "type": "string", "maxLength": 2000 },
          "resultMode":   { "type": "string",
                            "enum": ["replace","copy","diff","continueChat"] },
          "providerOverride": { "type": ["string","null"] }
        }
      }
    }
  }
}
```

`id`, `isBuiltIn`, `sortOrder` are NOT exported — they are re-generated on import.
Importing always APPENDS (never replaces) existing prompts.
If a prompt with identical `title` + `template` already exists, skip it (no duplicates).

---

## 18I — Ollama Model Not Pulled

Add a specific `AppError` case:
```swift
case ollamaModelNotFound(modelName: String)
// errorDescription: "Ollama model '\(modelName)' is not installed"
// recoverySuggestion: "Run in Terminal: ollama pull \(modelName)"
```

In `OllamaProvider.stream()`, detect a 404 response from the Ollama API
(which returns `{"error":"model 'llama3.2' not found"}`) and throw this case.

In `ErrorView`, for this error case, show a "Copy Command" button that copies
`ollama pull <modelName>` to the clipboard.

---

## 18J — Telemetry Policy

**No analytics. No telemetry. No data leaves the device. Ever.**

Explicitly document in `AppDelegate.swift`:
```swift
// AITextTool collects no analytics, telemetry, or usage data.
// No third-party tracking SDKs are used.
// All data (prompts, history, logs, API keys) is stored locally on this device only.
```

This comment serves as a reminder to future agents: do NOT add Sentry, Firebase,
Mixpanel, Amplitude, or any similar service. If a future agent suggests it, reject it.

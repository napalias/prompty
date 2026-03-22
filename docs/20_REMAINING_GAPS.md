# 20 — Remaining Gaps (Deep Audit Round 3)

This file amends all prior spec files. Every agent must read it.
Items are numbered 20A–20Z for traceability in review output.

---

## 20A — Swift Strict Concurrency (CRITICAL)

Set from day one in Xcode build settings:

```
SWIFT_STRICT_CONCURRENCY = complete
```

This means the build fails on any potential data race — not just warnings.
Every agent must ensure zero data-race warnings before pushing.

**Common patterns required:**

```swift
// ✅ Calling AppState from a background Task
Task {
    let text = try await captureService.capture()
    await MainActor.run {
        state.capturedText = text
        state.panelMode = .promptPicker
    }
}

// ✅ AppState is @MainActor — all its methods are implicitly @MainActor
@Observable @MainActor final class AppState { ... }

// ✅ Types crossing actor boundaries must be Sendable
struct AIRequest: Sendable { ... }
struct Prompt: Sendable { ... }

// ✅ Protocols used across actors
protocol AIProviderProtocol: Sendable { ... }

// ❌ WRONG — mutating AppState from background thread
Task.detached {
    state.isStreaming = true  // data race — compiler error with complete checking
}
```

**`nonisolated` keyword:** Use on methods that don't touch state and are called
from multiple actors (e.g. pure computation, `DiffCalculator.diff()`).

---

## 20B — Parallel Agent Merge Conflict: Integration Agent Role

When parallel agents modify the same shared files, a new role is needed
for cases where automatic rebase doesn't resolve conflicts cleanly.

### Integration Agent (new role — triggered only on LOOP_LIMIT_REACHED)

```
Trigger: Human pastes LOOP_LIMIT_REACHED output

Reads: Both branch diffs:
  git diff develop...feature/branch-a
  git diff develop...feature/branch-b

Responsibilities:
  1. Identify conflicting changes in shared files
  2. Produce a merged version that satisfies both branches' intent
  3. Create branch: fix/integration-<a>-<b>
  4. Apply merged files
  5. Run tests
  6. Output: INTEGRATION_AGENT_DONE or INTEGRATION_AGENT_FAILED

Does NOT: change business logic — only merges structural additions
```

### Shared file ownership table (reference for agents)

| File | Owned by | Parallel write rule |
|------|----------|---------------------|
| `AppState.swift` | Core architecture | Append-only: add new properties at end of relevant MARK section |
| `AppError.swift` | Core architecture | Append-only: add new cases in correct comment group |
| `04_ARCHITECTURE.md` | Documentation | Append-only to folder tree |
| `Info.plist` | Project setup | Never modify without spec update |
| `AITextTool.entitlements` | Project setup | Never modify without spec update |

---

## 20C — Hotkey Registration Failure Handling

`⌥Space` conflicts with macOS Input Sources switcher on systems with multiple
keyboard layouts. `CGEvent.tapCreate` can also fail for other reasons.

```swift
// HotkeyManager.register() must:
func register(keyCode: CGKeyCode, modifiers: CGEventFlags) throws {
    guard let tap = CGEvent.tapCreate(...) else {
        throw AppError.hotkeyRegistrationFailed(
            keyCode: keyCode,
            modifiers: modifiers,
            suggestion: "⌥Space may conflict with Input Sources. Try ⌃⌥Space in Settings."
        )
    }
    // ...
}
```

New `AppError` case:
```swift
case hotkeyRegistrationFailed(keyCode: UInt16, modifiers: UInt64, suggestion: String)
// errorDescription: "Could not register hotkey ⌥Space"
// recoverySuggestion: suggestion parameter
```

On registration failure, show a persistent banner in the menu bar popup
(not a panel — the panel requires the hotkey to open):

```swift
// MenuBarController — show warning badge on icon if hotkey failed
statusItem.button?.image = NSImage(systemSymbolName: "exclamationmark.triangle.fill", ...)
statusItem.button?.toolTip = "Hotkey registration failed — click to fix"
```

Clicking the menu bar icon when hotkey failed opens Settings directly to
the General tab with the hotkey field highlighted.

---

## 20D — Universal Node.js Binary for Sidecar

The bundled Node binary must run on both Apple Silicon (arm64) and Intel (x86_64).
While the user confirmed macOS 15+, they may use the app on Intel via screen sharing
or run the sidecar in a Rosetta environment.

```bash
# Download both architectures and lipo them together
# In Xcode build phase script:

ARM_URL="https://nodejs.org/dist/v20.12.0/node-v20.12.0-darwin-arm64.tar.gz"
X64_URL="https://nodejs.org/dist/v20.12.0/node-v20.12.0-darwin-x64.tar.gz"

# Only re-download if not present
if [ ! -f "$SRCROOT/AITextTool/Sidecar/node" ]; then
    curl -sL $ARM_URL | tar xz -C /tmp node-v20.12.0-darwin-arm64/bin/node
    curl -sL $X64_URL | tar xz -C /tmp node-v20.12.0-darwin-x64/bin/node

    lipo -create \
        /tmp/node-v20.12.0-darwin-arm64/bin/node \
        /tmp/node-v20.12.0-darwin-x64/bin/node \
        -output "$SRCROOT/AITextTool/Sidecar/node"

    chmod +x "$SRCROOT/AITextTool/Sidecar/node"
fi
```

The universal binary is ~110MB. It is in `.gitignore` and regenerated on each build.
CI must run this script before building — add it as the first build phase.

---

## 20E — Clipboard Race Condition Fix

`ClipboardFallbackReader` must detect if another app wrote to the clipboard
during the 80ms wait window:

```swift
func readSelectedText() async throws -> String {
    let pasteboard = NSPasteboard.general
    let savedChangeCount = pasteboard.changeCount

    simulateCopyKeystroke()
    try await Task.sleep(for: waitDuration)

    let newChangeCount = pasteboard.changeCount

    // If clipboard changed more than once, another app wrote during our window
    // (savedChangeCount + 1 = our ⌘C, anything beyond that = external write)
    if newChangeCount > savedChangeCount + 1 {
        // External write happened — do NOT restore (we'd overwrite user's clipboard)
        // Just read whatever is there now — it might be what they copied
        let text = pasteboard.string(forType: .string) ?? ""
        guard !text.isEmpty else { throw AppError.noTextSelected }
        return text
    }

    guard newChangeCount == savedChangeCount + 1 else {
        throw AppError.noTextSelected
    }

    let text = pasteboard.string(forType: .string) ?? ""
    // Safe to restore — only our write happened
    restoreClipboard(savedContents)
    guard !text.isEmpty else { throw AppError.noTextSelected }
    return text
}
```

Required new test:
```
test_read_externalWriteDuringWait_doesNotRestoreClipboard
test_read_externalWriteDuringWait_returnsExternalContent
```

---

## 20F — Sidecar Pipe Deadlock Prevention

**Critical:** Do NOT use `FileHandle.readDataToEndOfFile()` for sidecar stdout.
It reads the entire pipe into memory and blocks until the process exits.
With large AI responses, the OS pipe buffer (~64KB) fills up before the Swift
side reads it, causing the sidecar to block on write → deadlock.

**Use `DispatchIO` with a read loop:**

```swift
// SidecarManager.swift
private func startReading(from handle: FileHandle) {
    let channel = DispatchIO(
        type: .stream,
        fileDescriptor: handle.fileDescriptor,
        queue: .global(qos: .utility)
    ) { [weak self] error in
        if error != 0 { self?.handleSidecarCrash() }
    }

    var buffer = Data()
    channel.read(offset: 0, length: Int.max, queue: .global(qos: .utility)) { [weak self] done, data, error in
        guard let self else { return }
        if let data, !data.isEmpty {
            buffer.append(contentsOf: data)
            // Process complete newline-delimited JSON messages
            while let newlineRange = buffer.range(of: Data([0x0A])) {  // \n
                let line = buffer[..<newlineRange.lowerBound]
                buffer.removeSubrange(...newlineRange.lowerBound)
                self.processLine(Data(line))
            }
        }
        if done { channel.close() }
    }
}
```

---

## 20G — Session History Atomic Write

`SessionHistoryRepository` must write session files atomically to prevent
corruption on crash or power loss:

```swift
func save(_ session: ConversationSession) throws {
    let data = try JSONEncoder().encode(session)
    let fileURL = logDirectory.appendingPathComponent("\(session.id.uuidString).json")
    let tempURL = logDirectory.appendingPathComponent(".\(session.id.uuidString).tmp")

    // Write to temp file first
    try data.write(to: tempURL, options: .atomic)
    // .atomic uses a temp file + rename internally — but we make it explicit
    // for clarity and to handle the rename step ourselves:
    _ = try FileManager.default.replaceItemAt(fileURL, withItemAt: tempURL)
}
```

Apply the same atomic write pattern in `PromptRepository` and any other
repository that writes to disk.

---

## 20H — Prompt Template Injection Prevention

`{text}` placeholder substitution must be single-pass and not re-process
the selected text for placeholder patterns:

```swift
// PromptFormatter.swift
struct PromptFormatter {
    /// Fills template placeholders. Single-pass — the filled values
    /// are NOT scanned for further placeholders.
    static func build(template: String, selectedText: String, customInput: String) -> String {
        // Use a sentinel replacement to avoid double-substitution
        var result = template

        // Replace with a unique token first, then swap token for value
        let textToken = "___TEXT_SENTINEL_\(UUID().uuidString)___"
        let inputToken = "___INPUT_SENTINEL_\(UUID().uuidString)___"

        result = result.replacingOccurrences(of: "{text}", with: textToken)
        result = result.replacingOccurrences(of: "{input}", with: inputToken)

        // Now substitute actual values — they cannot introduce new {text} matches
        result = result.replacingOccurrences(of: textToken, with: selectedText)
        result = result.replacingOccurrences(of: inputToken, with: customInput)

        // If no {text} was in template, append selected text
        if !template.contains("{text}") && !template.contains("{input}") {
            result += "\n\n" + selectedText
        }

        return result
    }
}
```

---

## 20I — Edit Before Replace View

Missing UI mode: user can edit the AI result before replacing it in the source app.

### New PanelMode case
```swift
case editBeforeReplace  // editable TextEditor with confirm/cancel
```

### EditBeforeReplaceView
```swift
struct EditBeforeReplaceView: View {
    @Environment(AppState.self) var state
    var onConfirm: (String) -> Void
    var onCancel: () -> Void

    @State private var editedText: String = ""

    var body: some View {
        VStack(spacing: 8) {
            Label("Edit before replacing", systemImage: "pencil")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextEditor(text: $editedText)
                .font(.body)
                .frame(minHeight: 80, maxHeight: 200)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.separator))

            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.escape, modifiers: [])
                Spacer()
                Button("Replace", action: { onConfirm(editedText) })
                    .keyboardShortcut(.return, modifiers: [])
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .onAppear { editedText = state.streamingTokens }
    }
}
```

### Wire in ActionBarView
Add "Edit" button next to Replace/Copy/Diff:
```
[ ↩ Replace ]  [ ⌘↩ Copy ]  [ D Diff ]  [ E Edit ]  [ Esc Dismiss ]
```
`E` key → `state.panelMode = .editBeforeReplace`

---

## 20J — Recently Used Prompts

Track `lastUsedAt` on Prompt and show top 3 recently used at top of picker.

```swift
// Prompt model addition
struct Prompt: ... {
    // ... existing fields ...
    var lastUsedAt: Date? = nil  // nil = never used
}
```

```swift
// PromptPickerView — split into sections
var recentPrompts: [Prompt] {
    prompts
        .filter { $0.lastUsedAt != nil }
        .sorted { ($0.lastUsedAt ?? .distantPast) > ($1.lastUsedAt ?? .distantPast) }
        .prefix(3)
        .map { $0 }
}
```

```swift
// PromptRepository — update lastUsedAt on selection
func recordUsage(id: UUID) throws {
    var prompts = all()
    guard let index = prompts.firstIndex(where: { $0.id == id }) else { return }
    prompts[index].lastUsedAt = Date()
    try persist(prompts)
}
```

Called from `FloatingPanelController` immediately when user selects a prompt
(before the stream starts, so usage is recorded even if stream is cancelled).

New test:
```
test_recordUsage_updatesLastUsedAt
test_recentPrompts_returnsTop3ByRecency
test_recentPrompts_excludesNeverUsed
```

---

## 20K — Loading State (First Token Latency)

Between prompt selection and first streaming token, the panel shows nothing.
Typical latency: 0.5–2s. User needs feedback the request was sent.

### AppState addition
```swift
var isWaitingForFirstToken: Bool = false
```

Set `isWaitingForFirstToken = true` when stream starts.
Set `isWaitingForFirstToken = false` when first token arrives.

### StreamingResultView — loading shimmer
```swift
if state.isWaitingForFirstToken {
    VStack(alignment: .leading, spacing: 8) {
        // Skeleton lines — pulsing opacity animation
        ForEach(0..<3) { i in
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.secondary.opacity(0.2))
                .frame(maxWidth: i == 2 ? 120 : .infinity, height: 14)
                .shimmer()  // custom ViewModifier: opacity 0.4 → 0.8 repeating
        }
        Text("Thinking…")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
}
```

Respect `reduceMotion` — if true, show static skeleton without animation.

---

## 20L — Menu Bar Icon Specification

```swift
// MenuBarController.swift
statusItem.button?.image = {
    let img = NSImage(systemSymbolName: "wand.and.stars", accessibilityDescription: "AITextTool")!
    img.isTemplate = true  // ← REQUIRED: auto-inverts in dark mode and when highlighted
    return img
}()
```

**`isTemplate = true` is mandatory.** Without it:
- Icon is invisible when menu bar item is selected (dark background)
- Icon stays dark in macOS dark mode
- Fails review checklist item H1

### Hotkey-fired flash
```swift
func flashMenuBarIcon() {
    guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }
    let original = statusItem.button?.image
    let flash = NSImage(systemSymbolName: "wand.and.stars.inverse", ...)
    flash?.isTemplate = true
    statusItem.button?.image = flash
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
        self?.statusItem.button?.image = original
    }
}
```

---

## 20M — Build Number Auto-Increment

`CFBundleVersion` (build number) must increment on every build to allow
Sparkle to detect update order. Manually maintaining this is error-prone.

### Xcode Build Phase script (runs before Compile Sources)

```bash
#!/bin/bash
# Auto-set CFBundleVersion to git commit count
# This gives monotonically increasing build numbers tied to git history
BUILD_NUMBER=$(git rev-list --count HEAD)
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$INFOPLIST_FILE"
echo "Build number set to: $BUILD_NUMBER"
```

Add to `Info.plist`:
```xml
<key>CFBundleVersion</key>
<string>1</string>  <!-- placeholder, overwritten by build phase -->

<key>CFBundleShortVersionString</key>
<string>0.1.0</string>  <!-- manually set per release -->
```

Sparkle compares `CFBundleVersion` numerically. Each git commit increments it.
`CFBundleShortVersionString` is the human-readable version set before tagging.

---

## 20N — `Strings.swift` Constants File

All user-facing strings go in `Core/Utilities/Strings.swift`.
No hardcoded English strings in view files.

```swift
// Strings.swift
enum Strings {
    enum Panel {
        static let noTextSelected = "No text selected"
        static let thinking = "Thinking…"
        static let copied = "Copied to clipboard"
        static let retrying = "Retrying…"
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
    }

    enum Settings {
        static let apiKeyPlaceholder = "sk-••••••••"
        static let baseURLPlaceholder = "https://api.openai.com/v1"
        static let hotkeyDefault = "⌥Space"
        static let noLogsMessage = "No log files yet"
    }

    enum MenuBar {
        static let checkForUpdates = "Check for Updates…"
        static let settings = "Settings…"
        static let history = "History"
        static let quit = "Quit AITextTool"
        static let hotkeyHint = "Hotkey: ⌥Space"
    }
}
```

Review checklist H2 enforces this: grep for hardcoded English strings in Views.

---

## 20O — `PreviewData.swift` Contents

```swift
// Core/Utilities/PreviewData.swift
// Used exclusively in #Preview blocks — never in production code

enum PreviewData {
    static let shortText = "The quick brown fox jumps over the lazy dog."
    static let longText = """
        Artificial intelligence is transforming how we interact with computers.
        From natural language processing to computer vision, AI systems are
        becoming increasingly capable of understanding and generating human content.
        """
    static let codeText = """
        func calculateFibonacci(_ n: Int) -> Int {
            if n <= 1 { return n }
            return calculateFibonacci(n - 1) + calculateFibonacci(n - 2)
        }
        """

    static let prompts: [Prompt] = BuiltInPrompts.all

    static let streamingTokens = "Here is the improved version of your text with better clarity and flow."

    static let conversation: [AIMessage] = [
        AIMessage(role: .user, content: "Fix the grammar in: \(shortText)"),
        AIMessage(role: .assistant, content: streamingTokens),
        AIMessage(role: .user, content: "Make it more formal"),
        AIMessage(role: .assistant, content: "Herewith is a more formal rendition…")
    ]

    static let sampleError: AppError = .apiKeyInvalid(providerID: "anthropic-api")

    static func makeAppState(mode: PanelMode = .promptPicker) -> AppState {
        // No-side-effect factory — safe to call from previews
        let state = AppState()
        state.capturedText = shortText
        state.panelMode = mode
        if mode == .streaming {
            state.streamingTokens = streamingTokens
            state.isStreaming = false
        }
        return state
    }
}
```

### `AppState.init()` must have NO side effects

```swift
// AppState.swift
@Observable @MainActor
final class AppState {
    // All properties initialized to defaults — no network calls, no file I/O,
    // no timer starts in init. Side effects happen in AppDelegate.
    init() {}  // empty — safe for previews
}
```

---

## 20P — `Logger.swift` Subsystem and Categories

```swift
// Core/Utilities/Logger.swift
import os

// Single subsystem for all logging
private let subsystem = Bundle.main.bundleIdentifier ?? "com.aitexttool"

extension Logger {
    // One category per module — use these everywhere, never create ad-hoc loggers
    static let app      = Logger(subsystem: subsystem, category: "app")
    static let hotkey   = Logger(subsystem: subsystem, category: "hotkey")
    static let capture  = Logger(subsystem: subsystem, category: "capture")
    static let ai       = Logger(subsystem: subsystem, category: "ai")
    static let sidecar  = Logger(subsystem: subsystem, category: "sidecar")
    static let ui       = Logger(subsystem: subsystem, category: "ui")
    static let settings = Logger(subsystem: subsystem, category: "settings")
    static let history  = Logger(subsystem: subsystem, category: "history")
    static let update   = Logger(subsystem: subsystem, category: "update")
}

// Usage:
// Logger.ai.info("Stream started for provider: \(providerID)")
// Logger.capture.warning("AX reader failed, falling back to clipboard")
// Logger.sidecar.error("Process died with exit code: \(code)")
```

**NEVER log user content at any level:**
```swift
// ✅ Safe
Logger.capture.info("Captured text: \(text.count) chars")

// ❌ NEVER — user text could be sensitive
Logger.capture.info("Captured text: \(text)")  // F3 violation
```

---

## 20Q — Settings Window Keyboard Shortcut

Wire `⌘,` to open Settings — the macOS convention.

```swift
// AITextToolApp.swift or AppDelegate.swift
// SwiftUI way:
Settings {
    SettingsView()
}
// This automatically registers ⌘, on macOS

// OR AppKit way in AppDelegate:
func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.mainMenu?
        .item(withTitle: "AITextTool")?
        .submenu?
        .addItem(NSMenuItem(
            title: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        ))
}
```

Also add to the panel keyboard handler:
```swift
.onKeyPress(.init(","), modifiers: .command) {
    openSettingsWindow()
    return .handled
}
```

---

## 20R — Notarization and Code Signing Guide

For a personal tool, full notarization is optional but prevents Gatekeeper warnings.
Add this to `README.md` under "Distribution" section.

```bash
# One-time setup — only if you want notarized builds
xcrun notarytool store-credentials "AITextTool-notarize" \
    --apple-id "your@email.com" \
    --team-id "YOUR_TEAM_ID" \
    --password "app-specific-password"

# Sign the DMG
codesign --deep --force --verify --verbose \
    --sign "Developer ID Application: Your Name (TEAM_ID)" \
    AITextTool.app

# Notarize
xcrun notarytool submit AITextTool.dmg \
    --keychain-profile "AITextTool-notarize" \
    --wait

# Staple
xcrun stapler staple AITextTool.dmg
```

For personal use only (no distribution), skip notarization.
Users on your machine can bypass Gatekeeper with right-click → Open.

---

## 20S — Offline / No-Network Behaviour

When the device has no internet:
- Anthropic API / OpenAI → `URLError.notConnectedToInternet`
- Ollama → always works (local)
- OAuth sidecar → network error from Node process

**`NWPathMonitor` proactive check (optional but improves UX):**

```swift
// AIProviderManager.swift
import Network

private let pathMonitor = NWPathMonitor()
private(set) var isNetworkAvailable: Bool = true

func startMonitoringNetwork() {
    pathMonitor.pathUpdateHandler = { [weak self] path in
        DispatchQueue.main.async {
            self?.isNetworkAvailable = path.status == .satisfied
        }
    }
    pathMonitor.start(queue: .global(qos: .utility))
}
```

If `isNetworkAvailable == false` when stream is requested for a non-local provider,
throw `AppError.networkUnavailable` immediately without making the network call.

`ErrorView` for `networkUnavailable`:
- Icon: `wifi.slash`
- Message: "No internet connection"
- No retry button — the user must resolve the network issue themselves
- Show "Ollama (local) is still available" hint if Ollama is configured

---

## 20T — Dark Mode Panel Appearance

The `PanelAppearance` setting (auto/light/dark) must actually apply to the panel.

```swift
// FloatingPanelController.show()
func applyAppearance(_ appearance: PanelAppearance) {
    switch appearance {
    case .auto:
        panel.appearance = nil  // follows system
    case .light:
        panel.appearance = NSAppearance(named: .aqua)
    case .dark:
        panel.appearance = NSAppearance(named: .darkAqua)
    }
}
```

Call `applyAppearance` in `show()` every time the panel opens (settings may have changed).
Also observe `NSApp.effectiveAppearance` changes if `auto` is selected.

---

## 20U — `Package.resolved` Commit Rule

Add to `02_GITFLOW.md` scope list and `13_REVIEW_CHECKLIST.md`:

**Rule:** `Package.resolved` must be committed in the same commit as any
`Package.swift` change. Never commit one without the other.

Add to review checklist as **H6**:
```
- [ ] H6: If Package.swift was changed, Package.resolved was also committed
          in the same commit (check: git log --follow Package.resolved)
```

---

## 20V — Week 5 Build Task Updates

File 19W defined Week 5 tasks. Add these two missing ones:

### Task W5-7: Strings + PreviewData + Logger
```
Branch: chore/shared-utilities
Read: 20N (Strings.swift), 20O (PreviewData.swift), 20P (Logger.swift)
Implement:
- Core/Utilities/Strings.swift (all constants)
- Core/Utilities/PreviewData.swift (mock data)
- Core/Utilities/Logger.swift (categories)
- Update ALL existing views to use Strings.swift instead of hardcoded literals
- Update ALL existing #Preview blocks to use PreviewData
This task runs AFTER W3-1 (floating panel) is merged.
```

### Task W5-8: Performance Baseline
```
Branch: test/performance-baseline
Read: 12_TESTING.md (Performance Tests section), 20K (loading state)
Implement:
- AITextToolTests/Performance/PerformanceTests.swift
- Measure hotkey→capture latency (<50ms target)
- Measure PromptPickerView render with 20 prompts (<16ms target)
- Implement AppState.isWaitingForFirstToken + shimmer loading view
- Tests must use XCTMeasure — not manual timing
```

---

## 20W — Complete AppState.reset() Implementation

Referenced in 18B but never fully specified:

```swift
// AppState.swift
@MainActor
func reset(capturedText newText: String) {
    // MARK: - Captured text
    capturedText = newText
    let (truncated, wasTruncated) = TextCaptureService.truncateIfNeeded(newText)
    capturedText = truncated
    capturedTextWasTruncated = wasTruncated
    capturedTextOriginalLength = newText.count

    // MARK: - Streaming state
    streamingTokens = ""
    isStreaming = false
    isWaitingForFirstToken = false
    streamingError = nil
    streamingTask = nil         // task was already cancelled before reset is called
    lastResponseTokens = nil

    // MARK: - Panel state
    panelMode = .promptPicker
    panelMode_sessionRenderOverride = nil
    selectedPrompt = nil
    customPromptInput = ""

    // MARK: - Conversation
    conversationHistory = []
    // Note: currentSession is NOT reset here — endSession() handles it separately
}
```

---

## 20X — Summary of All Changes to Existing Files

For reference — what each prior spec file was changed to include:

| File | Changes in this round |
|------|-----------------------|
| `01_PROJECT_OVERVIEW.md` | Swift 5.10+, Xcode 16+, removed LaunchAtLogin, added Sparkle, added strict concurrency note |
| `02_GITFLOW.md` | Added parallel agent merge conflict protocol, rebase rules, shared file ownership table |
| `03_AGENT_PROTOCOL.md` | Updated file count reference, added LOOP_LIMIT_REACHED (max 5 iterations), Integration Agent role |
| `04_ARCHITECTURE.md` | Added @MainActor to AppState, missing files (Strings, PreviewData, DiffCalculator, ToastPanel, EditBeforeReplaceView, IntegrationTests), complete AppError case list |
| `12_TESTING.md` | Added PromptFormatter tests, performance tests, integration tests, UserDefaults isolation rule, PreviewData requirement |
| `13_REVIEW_CHECKLIST.md` | Added B7 (reduce motion), B8 (comments), E6 (branch staleness), G4 (MainActor), G5 (UserDefaults), Section H (5 new items) — total now 50 items |
| `15_CI_CD.md` | Runner macos-14→macos-15, Xcode 15→16 |
| `17_UPDATES_CRASHREPORTING_HISTORY.md` | Sparkle minimum version 13.0→15.0 |

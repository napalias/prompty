# 19 — Final Gaps & Deep Audit Fixes

This file covers 26 items found during final spec audit.
Agents implementing any module must read this file — it amends every prior spec file.

---

## 19A — macOS Version Correction (CRITICAL BUG FIX)

**Minimum: macOS 15 Sequoia.** All references to macOS 13 in prior files are superseded.

Benefits unlocked by targeting macOS 15:
- `@Observable` — no `ObservableObject`/`@Published` boilerplate needed
- `@Environment` value propagation is cleaner
- `SMAppService` for login items (no deprecated API)
- Latest SwiftUI layout engine (no workarounds)
- `NSPanel` fullscreen behaviour more predictable

In `DEPLOYMENT_TARGET` Xcode setting: `15.0`
In `Info.plist`: `LSMinimumSystemVersion = 15.0`
In CI `xcodebuild` commands: add `-destination 'platform=macOS,OS=15'`

---

## 19B — Sleep/Wake Cycle Handling

`CGEventTap` becomes invalid after system sleep. The Node sidecar process also dies.
Neither recovers automatically.

### Fix in AppDelegate

```swift
// AppDelegate.swift — add in applicationDidFinishLaunching
NSWorkspace.shared.notificationCenter.addObserver(
    self,
    selector: #selector(systemDidWake),
    name: NSWorkspace.didWakeNotification,
    object: nil
)

@objc func systemDidWake() {
    Logger.app.info("System woke from sleep — re-registering hotkey and restarting sidecar")
    // 1. Re-register event tap (it becomes invalid after sleep)
    try? hotkeyManager.reregister()
    // 2. Restart sidecar (process dies on sleep)
    sidecarManager.restart()
}
```

### HotkeyManagerProtocol addition

```swift
protocol HotkeyManagerProtocol: AnyObject {
    // ... existing methods ...
    func reregister() throws  // re-register same hotkey (call after wake)
}
```

### Required test

```
test_reregister_afterSleep_restoredHotkeyFires
```

---

## 19C — Single-Instance Enforcement

Two app instances fighting over the same hotkey and AX resources causes unpredictable
behaviour. Enforce a single running instance at launch.

```swift
// AppDelegate.applicationDidFinishLaunching
func enforcesSingleInstance() {
    let bundleID = Bundle.main.bundleIdentifier!
    let running = NSRunningApplication.runningApplications(
        withBundleIdentifier: bundleID
    )
    // running includes self, so count > 1 means a duplicate exists
    if running.count > 1 {
        let alert = NSAlert()
        alert.messageText = "AITextTool is already running"
        alert.informativeText = "Find it in your menu bar."
        alert.runModal()
        NSApp.terminate(nil)
    }
}
```

Call `enforcesSingleInstance()` as the first line of `applicationDidFinishLaunching`.

---

## 19D — OAuth Token Expiry Handling

Claude Code OAuth tokens expire. The sidecar will return an error response when
the token is stale.

### Sidecar error detection

When the sidecar returns:
```json
{ "type": "error", "requestId": "uuid", "message": "authentication failed" }
```

`AnthropicOAuthProvider` must catch this and throw:
```swift
case oauthTokenExpired
// errorDescription: "Your Claude subscription session has expired"
// recoverySuggestion: "Run 'claude login' in Terminal to reconnect"
```

### ErrorView for this case

Show a "Copy Command" button that copies `claude login` to clipboard.
Also show the command inline as a monospaced code block.

### Proactive check

`AnthropicOAuthProvider.isConfigured` should check token existence in Keychain
(already specified in 18A), but also check token age. If the stored token was
created more than 30 days ago, set `isConfigured = false` proactively and show
a yellow "Re-login required" badge in Provider Settings.

---

## 19E — Request Timeout Policy

Every AI provider MUST configure both connection timeout and streaming inactivity timeout.

```swift
// Applied in each provider's URLRequest setup:
var request = URLRequest(url: endpoint)
request.timeoutInterval = 30   // connection + first-byte timeout

// Streaming inactivity timeout (no token received for N seconds):
// Implemented as a separate Task that races the stream:

func streamWithTimeout<T>(
    stream: AsyncThrowingStream<T, Error>,
    inactivityLimit: Duration = .seconds(20)
) -> AsyncThrowingStream<T, Error> {
    AsyncThrowingStream { continuation in
        Task {
            var lastTokenTime = ContinuousClock.now
            let watchdog = Task {
                while true {
                    try await Task.sleep(for: .seconds(5))
                    if ContinuousClock.now - lastTokenTime > inactivityLimit {
                        continuation.finish(throwing: AppError.streamInterrupted)
                        return
                    }
                }
            }
            do {
                for try await token in stream {
                    lastTokenTime = ContinuousClock.now
                    continuation.yield(token)
                }
                watchdog.cancel()
                continuation.finish()
            } catch {
                watchdog.cancel()
                continuation.finish(throwing: error)
            }
        }
    }
}
```

Timeouts per provider:
| Provider | Connection timeout | Inactivity timeout |
|----------|-------------------|-------------------|
| Anthropic API | 30s | 20s |
| Anthropic OAuth | 60s | 30s (sidecar startup adds latency) |
| OpenAI | 30s | 20s |
| Ollama | 10s | 15s (local — should be fast) |

---

## 19F — App Quit While Streaming

`applicationShouldTerminate` must cancel in-flight work before allowing quit.

```swift
// AppDelegate.swift
func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    guard state.isStreaming else { return .terminateNow }

    // Cancel stream and sidecar cleanly, then terminate
    state.cancelStreaming()
    sidecarManager.stop()

    // Give 500ms for clean shutdown, then force terminate
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        NSApp.reply(toApplicationShouldTerminate: true)
    }
    return .terminateLater
}
```

---

## 19G — Auto-Copy on Panel Dismiss (Safety Net)

If the user dismisses the panel (Escape) while a completed result is visible
(not mid-stream), the result is silently auto-copied to the clipboard.

This prevents accidental loss of a generated result.

```swift
// FloatingPanelController.hide()
func hide() {
    // Safety net: if there's a completed result, copy it before dismissing
    if !state.isStreaming && !state.streamingTokens.isEmpty {
        textReplace.copyToClipboard(state.streamingTokens)
        // Brief visual feedback: flash the panel or show "Copied" toast
        showBriefToast("Copied to clipboard")
    }
    // ... animate out
    state.endSession()
    state.reset(capturedText: "")
}
```

Show a 1-second "Copied" toast overlay before the panel animates out.
Do NOT auto-copy if the user pressed Enter (replace) or ⌘Enter (explicit copy)
— only on Escape dismiss after result is shown.

---

## 19H — Paste Format: Plain Text vs Rich Text

### Per-prompt setting

Add to `Prompt` model:
```swift
var pasteMode: PasteMode = .plain

enum PasteMode: String, Codable, CaseIterable {
    case plain    // strips all formatting — safe everywhere
    case rich     // preserves markdown rendering via NSAttributedString
                  // only works in apps that accept rich clipboard (Pages, Mail, Word)
}
```

### ClipboardPasteWriter behaviour

```swift
func paste(text: String, mode: PasteMode) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    switch mode {
    case .plain:
        pasteboard.setString(text, forType: .string)
    case .rich:
        // Convert markdown to NSAttributedString using AttributedString
        if let attributed = try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            let nsAttr = NSAttributedString(attributed)
            pasteboard.writeObjects([nsAttr])
        } else {
            // Fallback to plain if markdown parsing fails
            pasteboard.setString(text, forType: .string)
        }
    }
    simulatePasteKeystroke()
}
```

### Built-in prompt defaults

- Fix Grammar → `.plain` (replaces prose, no formatting needed)
- Fix Code → `.plain` (terminal / editor will syntax highlight)
- Improve Writing → `.plain`
- All others → `.plain` (safest default)

User can override per-prompt in the prompt editor.

---

## 19I — Markdown Rendering in Result Panel

User wants choice: sometimes rendered markdown, sometimes plain.

### ResultRenderMode (per-prompt + global override)

```swift
enum ResultRenderMode: String, Codable, CaseIterable {
    case plain      // Text() — exactly what the model returned
    case markdown   // SwiftUI Text with markdown rendering
    case code       // Monospaced font, no markdown processing
}
```

Add to `Prompt` model:
```swift
var renderMode: ResultRenderMode = .markdown
```

Add global override toggle in Settings → General:
```
Result Display
○ Use per-prompt setting (default)
○ Always plain text
○ Always markdown
```
Global override stored in `AppSettings.resultRenderModeOverride: ResultRenderMode?`

### StreamingResultView implementation

```swift
struct StreamingResultView: View {
    @Environment(AppState.self) var state

    var effectiveRenderMode: ResultRenderMode {
        // Global override wins if set
        if let override = settings.resultRenderModeOverride {
            return override
        }
        return state.selectedPrompt?.renderMode ?? .markdown
    }

    var body: some View {
        ScrollView {
            Group {
                switch effectiveRenderMode {
                case .plain:
                    Text(state.streamingTokens)
                        .font(.body)
                        .textSelection(.enabled)

                case .markdown:
                    Text(LocalizedStringKey(state.streamingTokens))
                        .font(.body)
                        .textSelection(.enabled)
                    // Note: LocalizedStringKey renders markdown in SwiftUI Text

                case .code:
                    Text(state.streamingTokens)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        // Render mode toggle in action bar (quick override without going to settings)
        RenderModeToggle(current: effectiveRenderMode)
    }
}
```

### RenderModeToggle (in ActionBarView)

Small segmented control: `[ Aa ]  [ ✦ ]  [ </> ]`
(plain / markdown / code)
Tapping it sets a session-level override in `AppState.sessionRenderOverride`.
Resets to prompt default on panel dismiss.

### Built-in prompt render mode defaults

| Prompt | renderMode |
|--------|-----------|
| Fix Grammar | `.plain` |
| Improve Writing | `.markdown` |
| Summarise | `.markdown` |
| Translate | `.plain` |
| Explain | `.markdown` |
| Fix Code | `.code` |
| Make Formal/Casual | `.plain` |
| Continue Writing | `.markdown` |
| Custom | `.markdown` |

---

## 19J — OpenAI-Compatible Custom Base URL

Enables: Groq, LM Studio, Ollama OpenAI-compat mode, any self-hosted endpoint.

### ProviderConfig addition

```swift
struct ProviderConfig: Codable {
    let providerID: String
    var isEnabled: Bool
    var modelOverride: String?
    var customBaseURL: String?    // NEW — overrides default endpoint if set
}
```

### OpenAIProvider reads baseURL

```swift
// OpenAIProvider.swift
private var endpoint: URL {
    if let custom = config.customBaseURL,
       let url = URL(string: custom.trimmingCharacters(in: .whitespaces)),
       url.scheme == "https" || url.host == "localhost" {
        return url.appendingPathComponent("chat/completions")
    }
    return URL(string: "https://api.openai.com/v1/chat/completions")!
}
```

### Settings UI — Provider row expansion

When "ChatGPT (API Key)" row is expanded:
```
API Key:    [sk-••••••••••••••••]
Base URL:   [https://api.openai.com/v1     ] ← editable, placeholder shown
Model:      [gpt-4o                        ▼]
            ℹ️ Change Base URL to use Groq, LM Studio, or any OpenAI-compatible API
```

Validation: URL must start with `https://` OR `http://localhost`.

### Pre-set quick-fill buttons for common providers

Below the Base URL field:
```
Quick-fill: [OpenAI] [Groq] [LM Studio]
```

Values:
- OpenAI: `https://api.openai.com/v1`
- Groq: `https://api.groq.com/openai/v1`
- LM Studio: `http://localhost:1234/v1`

### isConfigured check for custom URL

If `customBaseURL` is set and non-empty, `isConfigured` requires only the base URL
to be valid — the API key can be empty (some local servers don't require auth).

---

## 19K — Default System Prompt

Without a system prompt, AI models preface every response with
"Sure! Here is the improved text:" — wasting tokens and cluttering the result.

### Default system prompt constant

```swift
// AIProviderManager.swift or PromptFormatter.swift
static let defaultSystemPrompt = """
You are a precise text transformation assistant. \
When given a task and text, output ONLY the transformed result. \
Do not include any preamble, explanation, sign-off, or meta-commentary. \
Do not say "Here is...", "Certainly!", "Sure!", or similar. \
Respond with the transformed text and nothing else.
"""
```

### How it merges with prompt-level system prompts

```swift
func buildSystemPrompt(for prompt: Prompt) -> String {
    guard let override = prompt.systemPromptOverride, !override.isEmpty else {
        return Self.defaultSystemPrompt
    }
    // Prompt-specific system prompt REPLACES the default (not appended)
    return override
}
```

Add `systemPromptOverride: String?` to `Prompt` model (nil = use default).
Expose it in the advanced prompt editor (collapsed by default, "Advanced ▼").

---

## 19L — Retry Logic on 5xx Errors

Network hiccups should auto-retry once. Permanent failures (4xx) never retry.

```swift
// In AIProviderManager.stream() — wrap the provider call
func streamWithRetry(request: AIRequest) -> AsyncThrowingStream<String, Error> {
    AsyncThrowingStream { continuation in
        Task {
            var lastError: Error?
            for attempt in 1...2 {   // max 2 attempts (1 retry)
                do {
                    for try await token in provider.stream(request: request) {
                        continuation.yield(token)
                    }
                    continuation.finish()
                    return
                } catch AppError.apiError(_, _) where attempt == 1 {
                    // 5xx type error — wait 1s and retry
                    Logger.ai.warning("Request failed, retrying (attempt \(attempt))")
                    lastError = error
                    try? await Task.sleep(for: .seconds(1))
                } catch {
                    // 4xx, cancellation, or second failure — don't retry
                    continuation.finish(throwing: error)
                    return
                }
            }
            continuation.finish(throwing: lastError ?? AppError.streamInterrupted)
        }
    }
}
```

Retry rules:
- Retry: `500`, `502`, `503`, `504`, network timeout, connection reset
- Never retry: `400`, `401`, `403`, `429`, `CancellationError`, `secureInputActive`
- Max retries: 1 (2 total attempts)
- Delay before retry: 1 second

Show user: during the 1s retry delay, show "Retrying…" in the streaming view
(not an error — don't switch to error mode).

---

## 19M — Token Counter & Cost Estimate

When using API key mode, show approximate token usage after each response.

### AppState addition

```swift
var lastResponseTokens: TokenUsage? = nil

struct TokenUsage {
    let inputTokens: Int
    let outputTokens: Int
    let providerID: String

    var estimatedCostUSD: Double? {
        switch providerID {
        case "anthropic-api":
            // claude-opus-4-5: $15/$75 per million in/out
            return (Double(inputTokens) * 15 + Double(outputTokens) * 75) / 1_000_000
        case "openai":
            // gpt-4o: $2.50/$10 per million in/out
            return (Double(inputTokens) * 2.5 + Double(outputTokens) * 10) / 1_000_000
        default:
            return nil  // Ollama and OAuth — no cost
        }
    }

    var display: String {
        var parts = ["\(inputTokens + outputTokens) tokens"]
        if let cost = estimatedCostUSD, cost > 0.0001 {
            parts.append(String(format: "~$%.4f", cost))
        }
        return parts.joined(separator: " · ")
    }
}
```

### Provider parsing

Anthropic API sends usage in the final `message_delta` event:
```json
{"type":"message_delta","usage":{"output_tokens":42}}
```
And in `message_start`:
```json
{"type":"message_start","message":{"usage":{"input_tokens":158}}}
```

OpenAI sends in the final chunk when `stream_options: {include_usage: true}` is set:
```json
{"usage":{"prompt_tokens":158,"completion_tokens":42}}
```
Add `"stream_options": {"include_usage": true}` to OpenAI request body.

### Display in ActionBarView

After streaming completes, show on the right side of the action bar:
```
[ ↩ Replace ]  [ ⌘↩ Copy ]  [ D Diff ]          347 tokens · ~$0.0031
```
Only shown for API key providers, not OAuth or Ollama.
Muted gray color (`secondary` foreground).

---

## 19N — Panel Height Clamping

No min/max panel height was defined. Without it, a long response makes the panel
taller than the screen.

```swift
// FloatingPanelController — update show() and repositionIfNeeded()
struct PanelSizeConstraints {
    static let width: CGFloat = 480
    static let minHeight: CGFloat = 200
    static let maxHeightFraction: CGFloat = 0.80  // 80% of visible screen height
}

// In FloatingPanel or FloatingPanelController
var maxAllowedHeight: CGFloat {
    let screen = NSScreen.main ?? NSScreen.screens[0]
    return screen.visibleFrame.height * PanelSizeConstraints.maxHeightFraction
}
```

`StreamingResultView`'s `ScrollView` must have `.frame(maxHeight: ...)` set.
The panel itself uses `.frame(minHeight: 200, maxHeight: maxAllowedHeight)`.

---

## 19O — Empty State Toast (No Text Selected)

When the hotkey fires but nothing is selected, opening a full panel to show an error
is disruptive. Use a lightweight toast instead.

```swift
// FloatingPanelController
func showNoTextSelectedToast(near point: NSPoint) {
    // Small toast, not the full panel
    // Auto-dismisses after 2 seconds, no interaction required
    let toast = ToastPanel(message: "No text selected", icon: "selection.pin.in.out")
    toast.show(near: point)
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        toast.dismiss()
    }
}
```

### ToastPanel

```swift
// ToastPanel.swift — separate small NSPanel
final class ToastPanel: NSPanel {
    init(message: String, icon: String) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 44),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        // Content: HStack { Image(systemName: icon); Text(message) }
        // Background: Capsule with .regularMaterial
        // Animate: fade in 0.1s, fade out 0.2s after delay
    }
}
```

The full error panel (`ErrorView`) is still used for actionable errors
(API key invalid, permission denied, OAuth expired). Toast is only for
the "no text selected" transient case.

---

## 19P — Fullscreen App Z-Order

When the frontmost app is in fullscreen mode (Final Cut Pro, Xcode fullscreen, games),
`NSPanel` with `.fullScreenAuxiliary` should appear above the fullscreen content.

The `collectionBehavior` setting in `FloatingPanel` already includes:
```swift
[.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
```

This is correct. However, `.stationary` prevents the panel from following
Space transitions. Since we want the panel to appear on the CURRENT Space
(wherever the user is), remove `.stationary` and replace with `.moveToActiveSpace`.

**Corrected `collectionBehavior`:**
```swift
collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .moveToActiveSpace]
```

This ensures:
- Panel appears on every Space when needed (`.canJoinAllSpaces`)
- Panel appears above fullscreen apps (`.fullScreenAuxiliary`)
- Panel moves to the active Space if shown while switching (`.moveToActiveSpace`)

---

## 19Q — Reduce Motion Support

```swift
// FloatingPanelController — check before animating
private var shouldAnimate: Bool {
    !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
}

func show(near point: NSPoint) {
    // ... positioning logic ...
    panel.alphaValue = 0
    panel.makeKeyAndOrderFront(nil)

    if shouldAnimate {
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }
    } else {
        panel.alphaValue = 1  // instant — no animation
    }
}
```

Same pattern for `hide()` and any other animations in the codebase.

Add to review checklist **B7**: "Any animation must check `shouldReduceMotion` via
`NSWorkspace.shared.accessibilityDisplayShouldReduceMotion`."

---

## 19R — Myers Diff Algorithm Specification

`DiffCalculator` must implement **Myers diff at word-level granularity**.

**Tokenization:** Split by whitespace AND punctuation boundaries.
Regex: `\b` word boundary split — treat each word and each punctuation run as a token.

```swift
// DiffCalculator.swift
struct DiffCalculator {
    enum Change: Equatable {
        case equal(String)
        case insert(String)
        case delete(String)
    }

    /// Returns word-level Myers diff between two strings.
    static func diff(original: String, revised: String) -> [Change] {
        let origTokens = tokenize(original)
        let revTokens = tokenize(revised)
        return myersDiff(origTokens, revTokens)
    }

    private static func tokenize(_ text: String) -> [String] {
        // Split on whitespace but preserve whitespace tokens
        // "Hello, world!" → ["Hello,", " ", "world!"]
        var tokens: [String] = []
        var current = ""
        for char in text {
            if char.isWhitespace {
                if !current.isEmpty { tokens.append(current); current = "" }
                tokens.append(String(char))
            } else {
                current.append(char)
            }
        }
        if !current.isEmpty { tokens.append(current) }
        return tokens
    }

    private static func myersDiff(_ a: [String], _ b: [String]) -> [Change] {
        // Standard Myers O(ND) algorithm implementation
        // Reference: Myers 1986 "An O(ND) Difference Algorithm and Its Variations"
        // ... (full implementation in source)
    }
}
```

`DiffView` renders `Change.insert` tokens with green background (`Color.green.opacity(0.2)`)
and `Change.delete` tokens with red background (`Color.red.opacity(0.2)`) inline in a
`Text` built from concatenated attributed strings.

---

## 19S — Code Comments Policy

Every agent must follow this rule. Add to review checklist as **B8**.

```swift
// ✅ CORRECT — comment explains WHY, not what
// Use DispatchIO rather than Pipe because Pipe has a 64KB buffer limit
// that causes deadlocks on large JSON-RPC payloads (sidecar responses)
self.stdoutHandle = DispatchIO(...)

// ❌ WRONG — comment restates what the code already shows
// Create the DispatchIO handle
self.stdoutHandle = DispatchIO(...)
```

**Rules:**
1. `// MARK: - Section Name` required at each logical section in files > 80 lines
2. Public protocol methods require `///` doc comments (Xcode Quick Help)
3. Non-obvious algorithm steps require inline comments
4. Every `// justified` comment on a force unwrap must explain why it cannot be nil
5. No commented-out code — use git history instead

---

## 19T — `.gitignore` Complete Definition

```gitignore
# Xcode
*.xcuserstate
xcuserdata/
DerivedData/
*.xcresult
*.xcarchive

# macOS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes

# SPM
.build/
*.resolved  # NOT ignored — commit Package.resolved for reproducible builds

# Sidecar (generated, not committed)
AITextTool/Sidecar/node
AITextTool/Sidecar/node_modules/

# CI / Build artefacts
coverage.json
Export/
*.dmg

# Secrets (NEVER commit)
sparkle_private.pem
.env
*.p12
*.pem
*.key

# Logs
*.log
```

---

## 19U — `ExportOptions.plist` Definition

Required by CI release workflow. Create at repo root.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <!-- For personal use without notarisation, use "mac-application" -->
    <!-- <string>mac-application</string> -->

    <key>destination</key>
    <string>export</string>

    <key>signingStyle</key>
    <string>automatic</string>

    <key>stripSwiftSymbols</key>
    <true/>

    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <!-- Find with: security find-identity -v -p codesigning -->
</dict>
</plist>
```

---

## 19V — `README.md` Required Contents

The W1-1 agent must create `README.md` at repo root with these sections:

```markdown
# AITextTool

> Select any text on macOS, press ⌥Space, pick a prompt, get AI results instantly.

## Screenshot
<!-- placeholder: add after first UI is built -->

## Requirements
- macOS 15 Sequoia or later
- Xcode 16+ (to build from source)
- Node.js is bundled — no install needed

## Quick Start
1. Clone the repo
2. Open `AITextTool.xcodeproj` in Xcode
3. Build & Run (⌘R)
4. Grant Accessibility + Input Monitoring permissions when prompted
5. Press ⌥Space on any selected text

## AI Providers
| Provider | Setup |
|----------|-------|
| Claude (API key) | Add key in Settings → Providers |
| Claude (Pro subscription) | Run `claude login` once, then select in Settings |
| OpenAI / Groq / LM Studio | Add key + base URL in Settings → Providers |
| Ollama (local) | Install Ollama, run `ollama pull llama3.2` |

## Hotkey
Default: ⌥Space — configurable in Settings → General

## Development
See `/spec` folder for complete architecture and agent instructions.

## Privacy
No data is sent to any server except your chosen AI provider.
No analytics, no telemetry. History and logs stored locally only.
```

---

## 19W — Build Plan: Missing Tasks from Spec Files 15–18

The following tasks are missing from `14_BUILD_PLAN.md` and must be added as **Week 5**:

### Task W5-1: GitHub Actions + Repo Housekeeping
```
Branch: chore/ci-setup
Read: 15_CI_CD.md, 19T (.gitignore), 19U (ExportOptions.plist), 19V (README)
Implement:
- .github/workflows/ci.yml
- .github/workflows/release.yml
- .github/scripts/check_coverage.py
- .gitignore (complete from 19T)
- ExportOptions.plist (from 19U)
- README.md (from 19V)
- .git/hooks/pre-push (lint hook)
```

### Task W5-2: Onboarding Wizard
```
Branch: feature/onboarding
Read: 18D, 19A
Implement:
- OnboardingViewModel.swift (@Observable, polls permissions every 2s)
- OnboardingView.swift (2-step wizard: Accessibility, Input Monitoring)
- Wire to AppDelegate: show on first launch, skip if both granted
- Store completion in UserDefaults["hasCompletedOnboarding"]
- Tests: OnboardingViewModelTests (mock AXIsProcessTrusted, mock IOHIDCheckAccess)
```

### Task W5-3: CrashReporter + Log Settings Tab
```
Branch: feature/crash-reporter
Read: 17B
Implement:
- CrashReporter.swift (signal handlers, exception handler, rotation)
- Add Logs tab to SettingsView
- Wire CrashReporter.shared in AppDelegate.applicationDidFinishLaunching
- Tests: CrashReporterTests (mock FileManager, mock signal delivery)
```

### Task W5-4: Session History
```
Branch: feature/session-history
Read: 17C
Implement:
- ConversationSession.swift (Codable model)
- SessionHistoryRepositoryProtocol.swift
- SessionHistoryRepository.swift (JSON files, 50-session retention)
- Wire startSession/appendToSession/endSession into AppState
- History submenu in MenuBarController (last 5 sessions)
- SessionHistoryView.swift (full list, read-only, Resume button)
- MockSessionHistoryRepository.swift
- All tests from 17C required tests section
```

### Task W5-5: Sparkle Auto-Update
```
Branch: feature/sparkle-updater
Read: 17A
Implement:
- Add Sparkle SPM dependency
- SUFeedURL and SUPublicEDKey in Info.plist (placeholder values)
- Wire SPUStandardUpdaterController in AppDelegate
- Add "Check for Updates…" to MenuBarController
- Document key generation steps in README under "Releases" section
Note: actual signing key is generated by human after task completes
```

### Task W5-6: Sleep/Wake + Single Instance
```
Branch: fix/runtime-stability
Read: 19B (sleep/wake), 19C (single instance), 19F (quit while streaming)
Implement:
- enforcesSingleInstance() in AppDelegate
- NSWorkspace.didWakeNotification handler → reregister hotkey + restart sidecar
- HotkeyManager.reregister()
- applicationShouldTerminate with clean Task/sidecar cancellation
- Tests for single instance detection and quit-while-streaming
```

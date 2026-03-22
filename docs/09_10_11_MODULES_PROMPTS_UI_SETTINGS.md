# 09 — Module: Prompts

## Prompt Model

```swift
struct Prompt: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var title: String           // "Fix Grammar"
    var icon: String            // SF Symbol name: "text.badge.checkmark"
    var template: String        // "Fix the grammar in: {text}"
    var resultMode: ResultMode
    var providerOverride: String? // nil = use default provider
    var isBuiltIn: Bool         // built-ins cannot be deleted
    var sortOrder: Int          // for ordering in picker
}

enum ResultMode: String, Codable, CaseIterable {
    case replace        // Enter → paste result back inline
    case copy           // ⌘Enter → copy to clipboard
    case diff           // show diff, user accepts/rejects
    case continueChat   // keep panel open for follow-up
}
```

## Built-In Prompts (BuiltInPrompts.swift)

```swift
static let all: [Prompt] = [
    Prompt(title: "Fix Grammar",       icon: "text.badge.checkmark",
           template: "Fix the grammar and spelling in the following text, preserving the original meaning and tone:\n\n{text}",
           resultMode: .replace),

    Prompt(title: "Improve Writing",   icon: "pencil.and.outline",
           template: "Improve the writing quality of the following text. Make it clearer, more concise, and more professional:\n\n{text}",
           resultMode: .diff),

    Prompt(title: "Summarise",         icon: "text.compress",
           template: "Summarise the following text in 2-3 sentences:\n\n{text}",
           resultMode: .copy),

    Prompt(title: "Translate → EN",    icon: "globe",
           template: "Translate the following text to English:\n\n{text}",
           resultMode: .replace),

    Prompt(title: "Explain",           icon: "questionmark.circle",
           template: "Explain the following in simple, clear terms:\n\n{text}",
           resultMode: .continueChat),

    Prompt(title: "Fix Code",          icon: "hammer",
           template: "Fix any bugs in the following code. Return only the corrected code with no explanation:\n\n{text}",
           resultMode: .replace),

    Prompt(title: "Make Formal",       icon: "briefcase",
           template: "Rewrite the following text in a formal, professional tone:\n\n{text}",
           resultMode: .diff),

    Prompt(title: "Make Casual",       icon: "face.smiling",
           template: "Rewrite the following text in a friendly, casual tone:\n\n{text}",
           resultMode: .diff),

    Prompt(title: "Continue Writing",  icon: "text.append",
           template: "Continue writing from where the following text ends, matching the style and tone:\n\n{text}",
           resultMode: .continueChat),

    Prompt(title: "Custom",            icon: "slider.horizontal.3",
           template: "{input}\n\n{text}",
           resultMode: .continueChat),
]
```

## PromptRepository

```swift
protocol PromptRepositoryProtocol {
    func all() -> [Prompt]
    func add(_ prompt: Prompt) throws
    func update(_ prompt: Prompt) throws
    func delete(id: UUID) throws     // throws if isBuiltIn
    func reorder(_ ids: [UUID]) throws
}
```

Storage: JSON file at `~/Library/Application Support/AITextTool/prompts.json`
On first launch: if file doesn't exist, seed with `BuiltInPrompts.all`.

---

# 10 — Module: UI

## FloatingPanel (NSPanel subclass)

```swift
final class FloatingPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 420),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        isMovableByWindowBackground = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        animationBehavior = .utilityWindow
    }
}
```

## FloatingPanelController

```swift
// Manages show/hide/position. Injected with AppState.
final class FloatingPanelController {
    func show(near point: NSPoint) {
        // Position panel: prefer above/left of cursor, adjust if off-screen
        // Animate in: alpha 0→1 + slight upward translate, 0.15s ease-out
    }

    func hide() {
        // Animate out: alpha 1→0, 0.10s, then orderOut
        // Reset AppState to initial state
    }
}
```

## MainPanelView

Routes to sub-views based on `AppState.panelMode`:

```swift
struct MainPanelView: View {
    @Environment(AppState.self) var state

    var body: some View {
        ZStack {
            // Background: rounded rect with vibrancy
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)

            // Content
            switch state.panelMode {
            case .promptPicker:   PromptPickerView()
            case .customInput:    TextInputView()
            case .streaming:      StreamingResultView()
            case .diff:           DiffView()
            case .continueChat:   ContinueChatView()
            case .error:          ErrorView()
            }
        }
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true) // height adapts to content
    }
}
```

## PromptPickerView

- Vertical list of prompt buttons (icon + title)
- Keyboard navigation: ↑↓ to move selection, Enter to confirm
- Search field at top (filters prompts by title)
- Last item is always "Custom" prompt → transitions to TextInputView
- Shows selected provider name at bottom right (small, muted)

## StreamingResultView

- `Text(state.streamingTokens)` — updates as tokens arrive
- Shows animated blinking cursor while `state.isStreaming == true`
- ActionBarView pinned at bottom showing keyboard hints
- Scrollable if content exceeds panel height

## ActionBarView

Displayed at bottom of StreamingResultView and ContinueChatView:

```
[  ↩ Replace  ]  [ ⌘↩ Copy ]  [ D Diff ]  [ Esc Dismiss ]
```

Only "Replace" and "Diff" appear if `resultMode` allows it.
Keys fire immediately — no button click needed.

## DiffView

Side-by-side layout:
- Left: original text (red background on removed words)
- Right: revised text (green background on added words)
- Bottom: [Accept → replace] [Reject → dismiss] [Edit → textInputView]
- Word-level diff using a simple LCS algorithm (implement in DiffCalculator.swift)

## ContinueChatView

- Shows conversation history (bubbles: user left, assistant right)
- TextField at bottom for follow-up prompt
- Enter sends, ⌘Enter copies last assistant message
- "Start Over" button resets to promptPicker

## Keyboard Handling

All keyboard events in the panel are handled in `MainPanelView` with `.onKeyPress`:

| Key | Action |
|-----|--------|
| Escape | Dismiss panel |
| Enter | resultMode == .replace → replace; else copy |
| ⌘Enter | Always copy to clipboard |
| D | Switch to diff view (if streaming is done) |
| ↑ / ↓ | Navigate prompt picker |
| ⌘, | Open settings |

---

# 11 — Module: Settings

## AppSettings Model

```swift
struct AppSettings: Codable, Equatable {
    var hotkey: HotkeySetting = HotkeySetting(keyCode: 49, modifiers: .maskAlternate)
    var activeProviderID: String = "anthropic-api"
    var providerConfigs: [String: ProviderConfig] = [:]
    var launchAtLogin: Bool = false
    var panelAppearance: PanelAppearance = .auto // auto/light/dark
}

struct HotkeySetting: Codable, Equatable {
    var keyCode: UInt16
    var modifiers: UInt64  // CGEventFlags raw value
}

enum PanelAppearance: String, Codable { case auto, light, dark }
```

## SettingsRepository (UserDefaults)

```swift
protocol SettingsRepositoryProtocol {
    func load() -> AppSettings
    func save(_ settings: AppSettings) throws
}
```

Storage: `UserDefaults.standard` with key `"app_settings"`.
Encode/decode with `JSONEncoder/JSONDecoder`.

## KeychainService

```swift
protocol KeychainServiceProtocol {
    func set(_ value: String, for key: String) throws
    func get(for key: String) throws -> String?
    func delete(for key: String) throws
}
```

Keys:
- `"api_key_anthropic"` — Anthropic API key
- `"api_key_openai"` — OpenAI API key

Use `Security.framework` `SecItemAdd/CopyMatching/Delete` directly.
Service name: `"com.aitexttool.keychain"`.

## Settings UI Structure

Three tabs:
1. **General** — hotkey recorder, launch at login, panel appearance
2. **Providers** — per-provider: enable toggle, API key field (SecureField), model picker, status indicator
3. **Prompts** — list with drag-to-reorder, add/edit/delete, import/export JSON

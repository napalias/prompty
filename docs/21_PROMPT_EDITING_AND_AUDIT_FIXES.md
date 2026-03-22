# 21 — In-Panel Prompt Editing, Audit Fixes & SwiftData History

This file amends spec files 04, 08, 09-11, 12, 13, 14, and 17.
All agents must read this file. It supersedes any conflicting prior spec.

---

## 21A — In-Panel Prompt Editing (New Feature)

### Design decisions confirmed by user:
- Trigger: pencil icon button next to each prompt row in picker
- Editor: full sheet/modal slides over the panel (not inline)
- Create: `+` button in the picker header creates new prompt from panel
- Built-in copy-on-edit: editing a built-in silently creates a personal
  copy and hides the original (never mutates built-in data)

---

### New PanelMode cases

Add to `PanelMode` enum in `04_ARCHITECTURE.md`:

```swift
enum PanelMode {
    case promptPicker
    case customInput
    case streaming
    case diff
    case continueChat
    case editBeforeReplace
    case error
    case promptEditor(prompt: Prompt?, isNew: Bool)
    // prompt = nil means creating new
    // isNew = true shows "Create" title, false shows "Edit"
}
```

---

### PromptPickerView — updated layout

```
┌─────────────────────────────────────────────────────┐
│  🔍 Search prompts…                           [ + ]  │  ← + creates new
├─────────────────────────────────────────────────────┤
│  RECENTLY USED                                       │
│  ✍️  Fix Grammar                          [ ✏️ ]     │
│  🌐  Translate → EN                       [ ✏️ ]     │
├─────────────────────────────────────────────────────┤
│  ALL PROMPTS                                         │
│  📋  Summarise                            [ ✏️ ]     │
│  💡  Explain                              [ ✏️ ]     │
│  🔨  Fix Code                             [ ✏️ ]     │
│  ✨  Improve Writing                      [ ✏️ ]     │
│  …                                                   │
└─────────────────────────────────────────────────────┘
```

Pencil icon (✏️) appears on hover only — hidden by default to keep the
list clean. On click → transitions to `promptEditor` mode.

`+` button in top-right header → transitions to `promptEditor(prompt: nil, isNew: true)`.

---

### PromptEditorView (new file: `UI/Views/PromptEditorView.swift`)

```swift
struct PromptEditorView: View {
    @Environment(AppState.self) var state
    @Environment(PromptEditorViewModel.self) var vm

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Header
            HStack {
                Button(action: vm.cancel) {
                    Label("Back", systemImage: "chevron.left")
                }
                .buttonStyle(.plain)

                Spacer()

                Text(vm.isNew ? "New Prompt" : "Edit Prompt")
                    .font(.headline)

                Spacer()

                Button(vm.isNew ? "Create" : "Save", action: vm.save)
                    .buttonStyle(.borderedProminent)
                    .disabled(!vm.isValid)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // MARK: - Form
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Icon + Title row
                    HStack(spacing: 12) {
                        // SF Symbol picker — tappable icon
                        Button(action: vm.showIconPicker) {
                            Text(vm.draft.icon.isEmpty ? "?" : "")
                            Image(systemName: vm.draft.icon.isEmpty
                                  ? "questionmark.square" : vm.draft.icon)
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .background(.quaternary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Choose icon")

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Title").font(.caption).foregroundStyle(.secondary)
                            TextField("e.g. Fix Grammar", text: $vm.draft.title)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    // Template
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Prompt Template").font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            // Variable hint buttons — tap to insert at cursor
                            Button("{text}") { vm.insertVariable("{text}") }
                                .buttonStyle(.bordered)
                                .font(.caption)
                                .foregroundStyle(.blue)
                            Button("{input}") { vm.insertVariable("{input}") }
                                .buttonStyle(.bordered)
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }

                        TextEditor(text: $vm.draft.template)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 100, maxHeight: 180)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(.separator))

                        // Live preview of filled template
                        if !vm.previewText.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Preview").font(.caption).foregroundStyle(.secondary)
                                Text(vm.previewText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(.quaternary)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }

                        // Validation warning: no {text} placeholder
                        if !vm.draft.template.contains("{text}") &&
                           !vm.draft.template.isEmpty {
                            Label(
                                "No {text} placeholder — selected text will be appended",
                                systemImage: "exclamationmark.triangle"
                            )
                            .font(.caption)
                            .foregroundStyle(.orange)
                        }
                    }

                    // Result Mode picker
                    VStack(alignment: .leading, spacing: 4) {
                        Text("After response").font(.caption).foregroundStyle(.secondary)
                        Picker("Result mode", selection: $vm.draft.resultMode) {
                            Text("Replace selected text").tag(ResultMode.replace)
                            Text("Copy to clipboard").tag(ResultMode.copy)
                            Text("Show diff").tag(ResultMode.diff)
                            Text("Continue chatting").tag(ResultMode.continueChat)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }

                    // Advanced section (collapsed by default)
                    DisclosureGroup("Advanced") {
                        VStack(alignment: .leading, spacing: 12) {

                            // System prompt override
                            VStack(alignment: .leading, spacing: 4) {
                                Text("System prompt (optional)")
                                    .font(.caption).foregroundStyle(.secondary)
                                TextEditor(text: $vm.draft.systemPromptOverride.bound)
                                    .font(.caption)
                                    .frame(minHeight: 60, maxHeight: 100)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(.separator))
                            }

                            // Provider override
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Provider override")
                                    .font(.caption).foregroundStyle(.secondary)
                                Picker("Provider", selection: $vm.draft.providerOverride.bound) {
                                    Text("Use default").tag(Optional<String>.none)
                                    ForEach(vm.availableProviders, id: \.id) { p in
                                        Text(p.displayName).tag(Optional(p.id))
                                    }
                                }
                            }

                            // Render mode
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Result display")
                                    .font(.caption).foregroundStyle(.secondary)
                                Picker("Render mode", selection: $vm.draft.renderMode) {
                                    Text("Markdown").tag(ResultRenderMode.markdown)
                                    Text("Plain text").tag(ResultRenderMode.plain)
                                    Text("Code").tag(ResultRenderMode.code)
                                }
                                .pickerStyle(.segmented)
                            }

                            // Paste mode
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Paste format")
                                    .font(.caption).foregroundStyle(.secondary)
                                Picker("Paste mode", selection: $vm.draft.pasteMode) {
                                    Text("Plain text").tag(PasteMode.plain)
                                    Text("Rich text").tag(PasteMode.rich)
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                    }
                    .font(.caption)

                    // Delete button (only for non-built-in prompts, not new)
                    if !vm.isNew && !vm.draft.isBuiltIn {
                        Button("Delete Prompt", role: .destructive, action: vm.delete)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(16)
            }
        }
    }
}
```

---

### PromptEditorViewModel (new file: `UI/Views/PromptEditorViewModel.swift`)

```swift
// PromptEditorViewModel.swift
@Observable
@MainActor
final class PromptEditorViewModel {
    // NOTE: This is a VIEW-LOCAL @Observable — it manages only the editor sheet.
    // It does NOT violate C2 (AppState is unique global state).
    // PromptEditorViewModel is ephemeral — created when sheet opens, deallocated on close.

    var draft: Prompt
    let isNew: Bool
    private let originalPrompt: Prompt?
    private let promptRepo: PromptRepositoryProtocol
    private let aiManager: AIProviderManager
    private weak var state: AppState?

    var availableProviders: [any AIProviderProtocol] { aiManager.providers }

    // Live preview: replaces {text} with a short example string
    var previewText: String {
        guard !draft.template.isEmpty else { return "" }
        return PromptFormatter.build(
            template: draft.template,
            selectedText: "…selected text…",
            customInput: "…custom input…"
        ).prefix(120).description
    }

    var isValid: Bool {
        !draft.title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !draft.template.trimmingCharacters(in: .whitespaces).isEmpty &&
        draft.title.count <= 50 &&
        draft.template.count <= 2_000
    }

    init(editing prompt: Prompt?, promptRepo: PromptRepositoryProtocol,
         aiManager: AIProviderManager, state: AppState) {
        self.isNew = (prompt == nil)
        self.originalPrompt = prompt
        self.promptRepo = promptRepo
        self.aiManager = aiManager
        self.state = state

        if let prompt {
            if prompt.isBuiltIn {
                // Copy-on-edit: make a mutable personal copy
                self.draft = Prompt(
                    id: UUID(),              // new id — independent copy
                    title: prompt.title,
                    icon: prompt.icon,
                    template: prompt.template,
                    resultMode: prompt.resultMode,
                    providerOverride: prompt.providerOverride,
                    isBuiltIn: false,        // personal copy is not built-in
                    sortOrder: prompt.sortOrder,
                    lastUsedAt: nil,
                    renderMode: prompt.renderMode,
                    pasteMode: prompt.pasteMode,
                    systemPromptOverride: prompt.systemPromptOverride
                )
            } else {
                self.draft = prompt
            }
        } else {
            // New prompt defaults
            self.draft = Prompt(
                id: UUID(),
                title: "",
                icon: "sparkles",
                template: "{text}",
                resultMode: .replace,
                providerOverride: nil,
                isBuiltIn: false,
                sortOrder: Int.max,
                lastUsedAt: nil,
                renderMode: .markdown,
                pasteMode: .plain,
                systemPromptOverride: nil
            )
        }
    }

    func save() {
        guard isValid else { return }
        do {
            if isNew {
                try promptRepo.add(draft)
            } else if let original = originalPrompt, original.isBuiltIn {
                // Built-in copy-on-edit:
                // 1. Add the personal copy
                try promptRepo.add(draft)
                // 2. Hide the original built-in from the picker
                //    (built-ins can't be deleted, but they can be hidden)
                try promptRepo.hide(id: original.id)
            } else {
                try promptRepo.update(draft)
            }
            state?.panelMode = .promptPicker
        } catch {
            state?.streamingError = error as? AppError ?? .keychainWriteFailed
            state?.panelMode = .error
        }
    }

    func delete() {
        guard !isNew, !draft.isBuiltIn else { return }
        try? promptRepo.delete(id: draft.id)
        state?.panelMode = .promptPicker
    }

    func cancel() {
        state?.panelMode = .promptPicker
    }

    func showIconPicker() {
        // TODO: simple icon picker — a grid of common SF Symbols
        // For now, cycles through a curated list
    }

    func insertVariable(_ variable: String) {
        draft.template += variable
    }
}
```

---

### C2 Review Checklist Amendment

`PromptEditorViewModel` is `@Observable` but is **not a violation of C2**.
Update C2 in `13_REVIEW_CHECKLIST.md`:

```
- [ ] C2  `AppState` is the single shared @Observable. View-local @Observable
          view models (e.g. PromptEditorViewModel, OnboardingViewModel) are
          allowed if they are: (a) ephemeral (not singletons), (b) not injected
          via .environment(), (c) own only transient UI state.
```

---

### PromptRepository — new `hide()` method

Built-in prompts cannot be deleted but can be hidden (suppressed from the picker)
when the user creates a personal copy via copy-on-edit.

```swift
protocol PromptRepositoryProtocol {
    func all() -> [Prompt]                    // returns non-hidden prompts only
    func allIncludingHidden() -> [Prompt]     // for Settings → Prompts management view
    func add(_ prompt: Prompt) throws
    func update(_ prompt: Prompt) throws
    func delete(id: UUID) throws              // throws if isBuiltIn
    func hide(id: UUID) throws                // hides built-in from picker (not delete)
    func unhide(id: UUID) throws              // restore hidden built-in
    func reorder(_ ids: [UUID]) throws
    func recordUsage(id: UUID) throws
}
```

Add `isHidden: Bool = false` to `Prompt` model.

Storage: `isHidden` persisted in `prompts.json` alongside other fields.

---

### Prompt model — final complete definition

```swift
struct Prompt: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var title: String
    var icon: String                          // SF Symbol name
    var template: String                      // may contain {text} and/or {input}
    var resultMode: ResultMode
    var renderMode: ResultRenderMode          // plain / markdown / code  (19I)
    var pasteMode: PasteMode                  // plain / rich             (19H)
    var providerOverride: String?             // nil = use active provider
    var systemPromptOverride: String?         // nil = use default system prompt (19K)
    var isBuiltIn: Bool
    var isHidden: Bool                        // hides built-in after copy-on-edit
    var sortOrder: Int
    var lastUsedAt: Date?                     // nil = never used         (20J)
}
```

---

### MainPanelView — wire promptEditor mode

```swift
switch state.panelMode {
case .promptPicker:             PromptPickerView()
case .customInput:              TextInputView()
case .streaming:                StreamingResultView()
case .diff:                     DiffView()
case .continueChat:             ContinueChatView()
case .editBeforeReplace:        EditBeforeReplaceView()
case .error:                    ErrorView()
case .promptEditor(let p, let isNew):
    PromptEditorView()
        .environment(PromptEditorViewModel(
            editing: p,
            promptRepo: promptRepo,
            aiManager: aiManager,
            state: state
        ))
}
```

The editor slides in from the right (`.transition(.move(edge: .trailing))`).
Back button slides it out. Respects `reduceMotion` (instant if true).

---

### Settings → Prompts tab — updated for new capabilities

The Settings Prompts tab now shows ALL prompts including hidden ones,
and lets the user unhide hidden built-ins:

```
┌──────────────────────────────────────────────────────┐
│  Prompts                                  [ + New ]  │
│                                                       │
│  MY PROMPTS (7)                                      │
│  ✍️  Fix Grammar (copy)     ⠿  [ Edit ]  [ Delete ] │
│  🌟  My Custom Prompt       ⠿  [ Edit ]  [ Delete ] │
│  …                                                    │
│                                                       │
│  BUILT-IN (hidden) (1)                               │
│  ✍️  Fix Grammar (original)     [ Restore ]          │
│                                                       │
│  BUILT-IN (3)                                        │
│  📋  Summarise               [ Edit → creates copy ] │
│  …                                                    │
│                                                       │
│  [ Import JSON ]  [ Export JSON ]                    │
└──────────────────────────────────────────────────────┘
```

⠿ = drag handle for reordering (only user prompts, not built-ins).

---

### New tests required

```
PromptEditorViewModelTests:
  test_init_withBuiltIn_createsMutableCopy
  test_init_withBuiltIn_copyHasNewID
  test_init_withBuiltIn_copyIsNotBuiltIn
  test_save_newPrompt_callsRepoAdd
  test_save_editingUserPrompt_callsRepoUpdate
  test_save_editingBuiltIn_callsAddAndHide
  test_save_invalidDraft_doesNothing
  test_delete_builtIn_doesNothing
  test_delete_userPrompt_callsRepoDelete
  test_previewText_fillsTextPlaceholder
  test_previewText_emptyTemplate_returnsEmpty
  test_isValid_emptyTitle_returnsFalse
  test_isValid_emptyTemplate_returnsFalse
  test_isValid_titleTooLong_returnsFalse
  test_isValid_validDraft_returnsTrue

PromptRepositoryTests (additions):
  test_hide_marksPromptAsHidden
  test_all_excludesHiddenPrompts
  test_allIncludingHidden_includesHiddenPrompts
  test_unhide_restoresPrompt
  test_hide_nonExistentID_throwsError
  test_recordUsage_updatesLastUsedAt
```

---

## 21B — SwiftData for Session History

Replace `SessionHistoryRepository` (file-based) with SwiftData.

### Model container setup in AppDelegate

```swift
// AppDelegate.swift
import SwiftData

var modelContainer: ModelContainer!

func applicationDidFinishLaunching(_ notification: Notification) {
    let schema = Schema([ConversationSession.self])
    let config = ModelConfiguration(
        schema: schema,
        url: FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AITextTool/AITextTool.sqlite"),
        allowsSave: true
    )
    modelContainer = try! ModelContainer(for: schema, configurations: [config])
    // Inject modelContainer.mainContext into SessionHistoryRepository
}
```

### ConversationSession as SwiftData model

```swift
// ConversationSession.swift
import SwiftData

@Model
final class ConversationSession {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var originalTextPreview: String   // first 500 chars — stored for search
    var providerID: String
    var promptTitle: String
    var messagesData: Data            // [AIMessage] JSON-encoded blob
    var finalResult: String?

    // Computed — not stored
    var messages: [AIMessage] {
        get { (try? JSONDecoder().decode([AIMessage].self, from: messagesData)) ?? [] }
        set { messagesData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    init(id: UUID = UUID(), createdAt: Date = Date(),
         originalText: String, providerID: String,
         promptTitle: String, messages: [AIMessage] = []) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.originalTextPreview = String(originalText.prefix(500))
        self.providerID = providerID
        self.promptTitle = promptTitle
        self.messagesData = (try? JSONEncoder().encode(messages)) ?? Data()
        self.finalResult = nil
    }
}
```

### SessionHistoryRepository with SwiftData

```swift
final class SessionHistoryRepository: SessionHistoryRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) { self.context = context }

    func save(_ session: ConversationSession) throws {
        context.insert(session)
        try context.save()
        try enforceRetentionLimit()
    }

    func all() -> [ConversationSession] {
        let descriptor = FetchDescriptor<ConversationSession>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func search(query: String) -> [ConversationSession] {
        let descriptor = FetchDescriptor<ConversationSession>(
            predicate: #Predicate {
                $0.originalTextPreview.localizedStandardContains(query) ||
                $0.promptTitle.localizedStandardContains(query)
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func delete(id: UUID) throws {
        let descriptor = FetchDescriptor<ConversationSession>(
            predicate: #Predicate { $0.id == id }
        )
        if let session = try? context.fetch(descriptor).first {
            context.delete(session)
            try context.save()
        }
    }

    func deleteAll() throws {
        try context.delete(model: ConversationSession.self)
        try context.save()
    }

    private func enforceRetentionLimit() throws {
        var descriptor = FetchDescriptor<ConversationSession>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchOffset = 50   // keep 50 most recent
        let old = (try? context.fetch(descriptor)) ?? []
        old.forEach { context.delete($0) }
        if !old.isEmpty { try context.save() }
    }
}
```

### Folder structure change

Remove from `04_ARCHITECTURE.md`:
- No more `history/` folder with individual JSON files
- Add `AITextTool.sqlite` in Application Support

Add to `04_ARCHITECTURE.md` under `Core/`:
```
│   ├── Data/
│   │   └── ConversationSession.swift    # @Model SwiftData entity
```

Remove from `17_UPDATES_CRASHREPORTING_HISTORY.md`:
- The `SessionHistoryRepository` file-per-session pattern
- The atomic write workaround (SwiftData handles this natively)
- The `~/Library/.../history/` folder reference

### SwiftData schema migration policy

When adding new fields to `ConversationSession` in future versions:
- Use `@Attribute` with a default value → SwiftData migrates automatically
- For breaking changes → define a `VersionedSchema` and `MigrationPlan`
- Document every migration in `CHANGELOG.md` under the relevant version

---

## 21C — @Observable Checklist Rule Fix

The C2 rule as written is wrong — it bans ALL `@Observable` except AppState,
but several legitimate view-local view models need it.

**Updated C2 (replaces old C2 in `13_REVIEW_CHECKLIST.md`):**

```
- [ ] C2  @Observable is used correctly:
         GLOBAL singletons: only AppState (injected via .environment)
         VIEW-LOCAL view models: allowed if ALL of:
           (a) ephemeral — created inside a view, not stored as singletons
           (b) NOT injected via .environment() across the whole app
           (c) own only transient UI state for one screen
         Examples of ALLOWED: PromptEditorViewModel, OnboardingViewModel
         Examples of FORBIDDEN: a second global state class, a shared cache class
```

---

## 21D — Focus and Keyboard Routing Fix

### The problem

`NSPanel` with `.nonactivatingPanel` prevents the panel from stealing
keyboard focus from the source app. This is correct for AX text replacement
(the source app must remain focused for `⌘V` to paste into it).

**BUT:** `.nonactivatingPanel` means SwiftUI `.onKeyPress` handlers inside
the panel will NOT fire — because the panel is not the key window.

### The solution: key window after capture

The sequence must be:
1. Hotkey fires
2. Capture text (AX reader runs — source app is still focused, AX element valid)
3. **Panel becomes key window** (`panel.makeKey()`) — source app loses focus
4. Panel receives keyboard events → `.onKeyPress` works
5. On Replace/Copy/Dismiss:
   - If Replace: re-activate source app first, then paste
   - If Copy/Dismiss: just close panel

```swift
// FloatingPanelController.show(near:)
func show(near point: NSPoint) {
    positionPanel(near: point)
    panel.makeKeyAndOrderFront(nil)  // panel becomes key window — intentional
    // Text was ALREADY captured before this call — source app focus no longer needed
    // for AX reading. Only needed again for paste (handled in TextReplaceService)
}
```

```swift
// TextReplaceService.replace(with:)
func replace(with text: String) async throws {
    // Re-activate source app BEFORE pasting so ⌘V goes to the right window
    if let sourceApp = NSWorkspace.shared.frontmostApplication,
       sourceApp.bundleIdentifier != Bundle.main.bundleIdentifier {
        sourceApp.activate(options: .activateIgnoringOtherApps)
        try await Task.sleep(for: .milliseconds(50))  // brief yield for activation
    }
    // Now paste
    try accessibilityWriter.writeSelectedText(text)
    // OR: clipboardPasteWriter.paste(text, mode: pasteMode)
}
```

```swift
// FloatingPanelController — override canBecomeKey
// NSPanel subclass must return true for makeKey() to work
final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }  // never main window
}
```

### Why `.nonactivatingPanel` stays in the style mask

Keep `.nonactivatingPanel` to prevent the panel from appearing in `⌘Tab`
app switcher and to prevent it from triggering app activation events.
`makeKey()` makes it the key window without making it the main app window.

---

## 21E — No-Provider State on Fresh Install

When user completes onboarding (permissions only) but has NOT yet added an
API key, the panel must guide them rather than showing a cryptic error.

### Detecting zero-configured providers

```swift
// AIProviderManager
var hasAnyConfiguredProvider: Bool {
    providers.contains { $0.isConfigured }
}
```

### FloatingPanelController — check before showing picker

```swift
func handleHotkeyFired() async {
    // If no providers configured, open Settings directly
    guard aiManager.hasAnyConfiguredProvider else {
        showNoProviderConfiguredPanel()
        return
    }
    // ... normal capture flow
}

func showNoProviderConfiguredPanel() {
    // Show a special one-time panel instead of the prompt picker:
    // ┌──────────────────────────────────────────────┐
    // │  ⚙️  Set up a provider to get started        │
    // │                                              │
    // │  Add an API key or connect Claude in         │
    // │  Settings to start using AITextTool.         │
    // │                                              │
    // │  [ Open Settings ]    [ Dismiss ]            │
    // └──────────────────────────────────────────────┘
    state.panelMode = .noProviderConfigured
    panelController.show(near: NSEvent.mouseLocation)
}
```

Add `case noProviderConfigured` to `PanelMode`.
Add `NoProviderView` to `UI/Views/`.

---

## 21F — JSON Decoding Resilience

All `JSONDecoder` calls on persisted data must handle decode failures
gracefully — never crash, never show a blank state silently.

### Rule for every repository

```swift
// Pattern to use in PromptRepository, SettingsRepository, etc.
func load() -> AppSettings {
    guard let data = defaults.data(forKey: "app_settings") else {
        return AppSettings()  // first launch defaults
    }
    do {
        return try JSONDecoder().decode(AppSettings.self, from: data)
    } catch {
        // Decode failed — data may be from an older version or corrupt
        Logger.settings.error("Failed to decode AppSettings: \(error). Using defaults.")
        // Backup the corrupt data before overwriting
        defaults.set(data, forKey: "app_settings_backup_\(Date().timeIntervalSince1970)")
        return AppSettings()  // safe defaults
    }
}
```

Rules:
1. Never `try!` decode persisted data — always `do/catch`
2. On failure: log the error, back up raw data with timestamp key, return safe defaults
3. The backup key lets you diagnose what went wrong without losing data
4. Add to review checklist as **D9**: "No `try!` or force-unwrapped `try?` on persisted data decode"

---

## 21G — Model Staleness (Deprecated AI Models)

Hardcoded model names (`claude-opus-4-5`, `gpt-4o`) will become invalid
when providers deprecate them. The app should not crash or silently
send requests to a non-existent model.

### Error handling

When the API returns a 404 or "model not found" error, map to:
```swift
case modelNotFound(providerID: String, modelName: String)
// errorDescription: "Model '\(modelName)' is not available"
// recoverySuggestion: "Update the model in Settings → Providers"
```

### Model constants — not hardcoded strings scattered in provider files

```swift
// Core/Constants/ModelConstants.swift
enum ModelConstants {
    enum Anthropic {
        static let defaultModel = "claude-opus-4-5"
        static let availableModels = [
            "claude-opus-4-5",
            "claude-sonnet-4-5",
            "claude-haiku-4-5"
        ]
    }
    enum OpenAI {
        static let defaultModel = "gpt-4o"
        static let availableModels = [
            "gpt-4o",
            "gpt-4o-mini",
            "gpt-4-turbo",
            "o1-preview",
            "o1-mini"
        ]
    }
}
```

The `availableModels` list is a fallback for the model picker in Settings.
For Ollama, the real list comes from `GET /api/tags` — no constants needed.

---

## 21H — Sidecar Orphan Process Prevention

If the app crashes without `applicationShouldTerminate` running,
the `sidecar.js` Node process becomes an orphan consuming memory and CPU.

### Prevention: parent death signal

In `SidecarManager`, after spawning the process:

```swift
// sidecar.js — add at startup
process.on('disconnect', () => {
    // Parent process disconnected — exit cleanly
    process.exit(0)
})

// Also: poll parent every 5s; if parent PID is gone, exit
setInterval(() => {
    try {
        process.kill(process.ppid, 0)  // signal 0 = check if process exists
    } catch {
        process.exit(0)  // parent is gone
    }
}, 5000)
```

```swift
// SidecarManager.swift — set process group so kill(-pgid) works
process.qualityOfService = .utility
// Store PID for emergency cleanup
UserDefaults.standard.set(process.processIdentifier, forKey: "sidecar_pid")
```

On app launch, check for orphan:
```swift
// AppDelegate.applicationDidFinishLaunching
if let orphanPID = UserDefaults.standard.value(forKey: "sidecar_pid") as? Int32 {
    kill(orphanPID, SIGTERM)  // clean up previous orphan if any
    UserDefaults.standard.removeObject(forKey: "sidecar_pid")
}
```

---

## 21I — Build Plan: New Tasks

Add to Week 4 (alongside existing W4 tasks):

### Task W4-5: In-Panel Prompt Editing
```
Branch: feature/prompt-editor
Depends on: W3-1 (floating panel) merged
Read: 21A in full
Implement:
- PromptEditorViewModel.swift (with all tests from 21A)
- PromptEditorView.swift (full sheet UI)
- Update PromptPickerView: pencil icon on hover, + button in header
- Update PromptRepository: add hide(), unhide(), allIncludingHidden(), recordUsage()
- Update Prompt model: add isHidden, renderMode, pasteMode, systemPromptOverride, lastUsedAt
- Update MainPanelView: wire .promptEditor PanelMode case
- Update Settings Prompts tab: show hidden built-ins with Restore button
- All tests from 21A required tests section
```

### Task W4-6: No-Provider State + JSON Decode Resilience
```
Branch: fix/empty-state-resilience
Depends on: W3-1 merged
Read: 21E, 21F
Implement:
- AIProviderManager.hasAnyConfiguredProvider
- NoProviderView.swift
- PanelMode.noProviderConfigured case
- Decode resilience pattern in PromptRepository and SettingsRepository
- ModelConstants.swift
- Tests: test_hasAnyConfiguredProvider_whenNoneConfigured_returnsFalse
         test_decode_corruptData_returnsDefaults_andLogsError
```

Add to Week 5:

### Task W5-9: SwiftData Session History Migration
```
Branch: feature/swiftdata-history
Depends on: W5-4 (original history task — do NOT start W5-4, replace with this)
Read: 21B in full
Implement:
- Remove old SessionHistoryRepository (file-based) entirely
- Add ConversationSession as @Model
- Implement SessionHistoryRepository with ModelContext
- Wire ModelContainer in AppDelegate
- Update SessionHistoryView to use @Query for real-time updates
- Tests: mock ModelContext via in-memory ModelContainer
  (ModelConfiguration(isStoredInMemoryOnly: true))
```

---

## 21J — Review Checklist Final Additions

Add these items to `13_REVIEW_CHECKLIST.md`:

**Section D (Code Quality):**
```
- [ ] D9  No `try!` or forced `try?` on any JSON decode of persisted data
          — all persistence reads use do/catch with fallback to defaults (21F)
```

**Section F (Security):**
```
- [ ] F5  No user-entered text stored in UserDefaults — only in
          Keychain (API keys) or JSON/SwiftData (history, prompts)
```

**Section H (Completeness):**
```
- [ ] H7  Sidecar spawns with orphan-prevention polling (21H)
- [ ] H8  canBecomeKey returns true on FloatingPanel (21D)
- [ ] H9  TextReplaceService re-activates source app before paste (21D)
- [ ] H10 AIProviderManager.hasAnyConfiguredProvider checked before
          showing prompt picker (21E)
```

---

## 21K — Updated Complete PanelMode Enum

```swift
// Definitive enum — supersedes all prior definitions
enum PanelMode: Equatable {
    case promptPicker                           // initial state
    case customInput                            // free-text prompt entry
    case streaming                              // live token display
    case diff                                   // side-by-side old/new
    case continueChat                           // multi-turn follow-up
    case editBeforeReplace                      // edit result before pasting (20I)
    case error                                  // error display
    case noProviderConfigured                   // fresh install, no API keys (21E)
    case promptEditor(prompt: Prompt?, isNew: Bool)  // in-panel editor (21A)
}
```

Static conformance for `Equatable` on `promptEditor`:
```swift
static func == (lhs: PanelMode, rhs: PanelMode) -> Bool {
    switch (lhs, rhs) {
    case (.promptEditor(let a, let b), .promptEditor(let c, let d)):
        return a?.id == c?.id && b == d
    // ... other cases via default
    default:
        return String(describing: lhs) == String(describing: rhs)
    }
}
```

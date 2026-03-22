# 14 — Build Plan

## Week-by-Week Agent Assignments

Each row = one Claude Code agent session.
Agents within the same week can run in parallel IF their dependencies are met.

---

## Week 1 — Foundation (Sequential, no parallelism yet)

### Task W1-1: Xcode Project Setup
**Branch:** `chore/xcode-project-setup`  
**Agent prompt:**
```
Read all files in /spec. 
Create the Xcode project for AITextTool with:
- macOS app target, minimum macOS 15
- App Sandbox disabled in entitlements
- NSAccessibilityUsageDescription in Info.plist
- LSUIElement = true in Info.plist
- Exact folder structure from 04_ARCHITECTURE.md
- Empty placeholder .swift files for every file listed in the structure
- SwiftLint SPM plugin added
- .swiftlint.yml with rules: force_unwrapping, force_try, no_print, file_length (250), function_body_length (40), explicit_type_interface
- AITextToolTests target with matching folder structure
- All mock files in AITextToolTests/Mocks/
- An AppError.swift with all error cases from 04_ARCHITECTURE.md
- A Logger.swift wrapping os.Logger
Then commit, push, run review loop.
```
**Acceptance:** Project compiles. All placeholder files exist. SwiftLint passes.

---

### Task W1-2: AppState + AppDelegate + MenuBar
**Branch:** `feature/app-foundation`  
**Depends on:** W1-1 merged  
**Agent prompt:**
```
Read all files in /spec.
Implement:
- AppState.swift (@Observable) with all properties from 04_ARCHITECTURE.md
- AITextToolApp.swift (@main, creates AppState, AppDelegate, wires everything)
- AppDelegate.swift (NSApplicationDelegate, holds FloatingPanelController ref)
- MenuBarController.swift (NSStatusItem with icon "wand.and.stars", menu: "Settings", "Quit")
- PanelMode enum
Tests: AppState should be observable (test that changing a property triggers update).
```

---

## Week 2 — Core Services (Can run in parallel after W1-2)

### Task W2-1: HotkeyManager
**Branch:** `feature/hotkey-manager`  
**Agent prompt:**
```
Read all files in /spec. Implement 05_06_07_MODULES spec section 05.
Files: HotkeyManagerProtocol.swift, HotkeyManager.swift (CGEventTap),
MockHotkeyManager.swift, HotkeyManagerTests.swift
All tests from 12_TESTING.md HotkeyManager section must pass.
```

### Task W2-2: TextCaptureService
**Branch:** `feature/text-capture`  
**Agent prompt:**
```
Read all files in /spec. Implement 05_06_07_MODULES spec section 06.
Files: TextCaptureServiceProtocol.swift, TextCaptureService.swift,
AccessibilityReader.swift, ClipboardFallbackReader.swift,
PermissionChecker.swift, MockTextCaptureService.swift,
and all tests from 12_TESTING.md TextCapture section.
```

### Task W2-3: TextReplaceService
**Branch:** `feature/text-replace`  
**Agent prompt:**
```
Read all files in /spec. Implement 05_06_07_MODULES spec section 07.
Files: TextReplaceServiceProtocol.swift, TextReplaceService.swift,
AccessibilityWriter.swift, ClipboardPasteWriter.swift,
MockTextReplaceService.swift,
and all tests from 12_TESTING.md TextReplaceService section.
```

### Task W2-4: AI Providers
**Branch:** `feature/ai-providers`  
**Agent prompt:**
```
Read all files in /spec. Implement 08_MODULE_AI_PROVIDERS.md in full.
Files: AIProviderProtocol.swift, AIProviderManager.swift, AIMessage.swift,
AIRequest.swift, SSEParser.swift, AnthropicProvider.swift,
OpenAIProvider.swift, OllamaProvider.swift, MockAIProvider.swift,
and ALL tests from 12_TESTING.md AI section.
Use a protocol-based URLSession mock (MockURLSession) for network tests.
The sidecar.js and AnthropicOAuthProvider.swift are NOT part of this task —
they are W3-2.
```

### Task W2-5: PromptRepository
**Branch:** `feature/prompt-store`  
**Agent prompt:**
```
Read all files in /spec. Implement 09_10_11 spec section 09.
Files: Prompt.swift, ResultMode.swift, BuiltInPrompts.swift,
PromptRepositoryProtocol.swift, PromptRepository.swift (JSON file storage),
MockPromptRepository.swift,
and all tests from 12_TESTING.md PromptRepository section.
Use a MockFileManager injected into PromptRepository for tests.
```

### Task W2-6: Settings + Keychain
**Branch:** `feature/settings-core`  
**Agent prompt:**
```
Read all files in /spec. Implement 09_10_11 spec section 11 (models + repos only, no UI yet).
Files: AppSettings.swift, HotkeySetting.swift, ProviderConfig.swift,
SettingsRepositoryProtocol.swift, SettingsRepository.swift,
KeychainServiceProtocol.swift, KeychainService.swift,
MockSettingsRepository.swift, MockKeychainService.swift,
and all tests from 12_TESTING.md Settings + Keychain sections.
```

---

## Week 3 — UI + OAuth (Some parallel)

### Task W3-1: Floating Panel + Main Panel View
**Branch:** `feature/floating-panel`  
**Depends on:** W2-1, W2-2, W2-4, W2-5 all merged into develop  
**Agent prompt:**
```
Read all files in /spec. Implement 09_10_11 spec section 10 (all UI).
Wire AppState to FloatingPanelController.
Wire HotkeyManager: on hotkey fire → capture text → show panel.
All views must be implemented. SwiftUI Previews required for each view.
```

### Task W3-2: Claude OAuth Sidecar
**Branch:** `feature/anthropic-oauth`  
**Depends on:** W2-4 merged  
**Agent prompt:**
```
Read all files in /spec, especially 08_MODULE_AI_PROVIDERS.md sidecar section.
Implement:
- AITextTool/Sidecar/sidecar.js (Node.js, uses @anthropic-ai/claude-agent-sdk)
- AITextTool/Sidecar/package.json
- AnthropicOAuthProvider.swift (spawns sidecar, communicates via stdin/stdout JSON)
- SidecarManager.swift (lifecycle: spawn, keep-alive, restart on crash)
- Tests: AnthropicOAuthProviderTests.swift using a MockSidecarProcess
```

### Task W3-3: Settings UI
**Branch:** `feature/settings-ui`  
**Depends on:** W2-6 merged, W3-1 merged  
**Agent prompt:**
```
Read all files in /spec. Implement Settings UI from 09_10_11 spec section 11.
Files: SettingsWindowController.swift, SettingsView.swift,
ProvidersSettingsView.swift, PromptsSettingsView.swift,
GeneralSettingsView.swift.
Wire to SettingsRepository and KeychainService.
Add "Open Settings" to MenuBarController menu.
SwiftUI Previews required for all settings views.
```

---

## Week 4 — Result Actions + Polish

### Task W4-1: Result Actions (Replace, Copy, Diff)
**Branch:** `feature/result-actions`  
**Depends on:** W3-1 merged  
**Agent prompt:**
```
Read all files in /spec. Implement:
- ActionBarView.swift (keyboard hints, key handlers)
- DiffCalculator.swift (LCS word-level diff algorithm)
- DiffView.swift (side-by-side, Accept/Reject/Edit)
- Wire Enter → TextReplaceService.replace() → dismiss panel
- Wire ⌘Enter → TextReplaceService.copyToClipboard() 
- Wire D → switch to diff view
- Wire Escape → dismiss panel
- All tests from 12_TESTING.md DiffCalculator section.
```

### Task W4-2: Continue Chat
**Branch:** `feature/continue-chat`  
**Depends on:** W3-1 merged  
**Agent prompt:**
```
Read all files in /spec. Implement:
- ContinueChatView.swift (conversation bubbles, follow-up input)
- Wire conversation history in AppState (add AIMessage per turn)
- Wire AIProviderManager to pass history in AIRequest
- "Start Over" clears history, returns to promptPicker mode
- Tests: conversation history accumulates correctly across turns
```

### Task W4-3: Error Handling + Edge Cases
**Branch:** `feature/error-handling`  
**Depends on:** W3-1, W3-2, W4-1 merged  
**Agent prompt:**
```
Read all files in /spec. Implement:
- ErrorView.swift (friendly error message + recovery suggestion from AppError)
- Wire all AppError cases through the UI
- Handle: no text selected, permission denied, Ollama not running,
  API key invalid, rate limited, network unavailable, stream interrupted
- Add retry button where appropriate
- Ensure panel never shows a raw error message — always a human-friendly one
- Tests: each AppError maps to correct errorDescription and recoverySuggestion
```

### Task W4-4: LaunchAtLogin + Final Polish
**Branch:** `feature/launch-at-login`  
**Depends on:** W3-3 merged  
**Agent prompt:**
```
Read all files in /spec. Implement:
- LaunchAtLogin integration in GeneralSettingsView using SMAppService
- Panel open/close animations (alpha + translate, exact durations from spec)
- Dark/light mode support (panel respects system or user override)
- Empty state in PromptPickerView (when search yields no results)
- PromptPickerView search filtering
- Keyboard navigation (↑↓) in PromptPickerView
- Accessibility labels on all interactive elements (VoiceOver support)
```

---

## Final Integration Checklist (Human task)

Before tagging v0.1.0:
- [ ] All feature branches merged to develop
- [ ] All tests pass on develop
- [ ] SwiftLint passes on develop
- [ ] Manual smoke test: select text in Safari, Notes, VS Code, Terminal
- [ ] Manual smoke test: hotkey fires, panel shows, prompt runs, result shows
- [ ] Manual smoke test: settings persist across app restart
- [ ] App notarized (optional for personal use, but good practice)
- [ ] Merge develop → main, tag v0.1.0

---

## Agent Prompt Template (copy-paste for each task)

```
You are working on AITextTool, a macOS menu bar app.

FIRST: Read all files in the /spec folder in order (00_INDEX.md through 13_REVIEW_CHECKLIST.md). 
Do not write any code until you have read all spec files.

TASK: [PASTE TASK DESCRIPTION FROM BUILD PLAN]

BRANCH: Create branch [BRANCH NAME] from develop.

CONSTRAINTS:
- Do not modify any files outside the scope of this task
- Do not add features not described in the spec
- Every new public method must have tests
- Follow all rules in 13_REVIEW_CHECKLIST.md proactively

When done, output:
FEATURE_AGENT_DONE
branch: [branch name]
commits: [N]
tests_added: [N]
files_changed: [list]
```

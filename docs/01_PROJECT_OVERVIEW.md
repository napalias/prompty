# 01 — Project Overview

## App Name
**AITextTool** (working title, rename freely)

## One-Line Description
A macOS menu bar app that captures any selected text system-wide via a hotkey,
sends it to an AI provider with a chosen prompt, streams the result in a floating
panel, and lets the user replace the original text, copy, diff, or continue chatting.

---

## Goals

1. Works system-wide — any app (Chrome, VS Code, Notes, Terminal, PDF viewers)
2. Triggered by a configurable global hotkey (default: ⌥Space)
3. Supports multiple AI providers: Claude (subscription via OAuth OR API key),
   OpenAI (API key), Ollama (local)
4. Prompts are fully customisable — built-in library + user-defined
5. Results stream token-by-token (live typing feel)
6. Result actions: Replace inline (Enter), Copy (⌘Enter), Diff view (D), Continue prompting
7. Zero friction — panel appears in under 200ms after hotkey, dismisses on Escape
8. Settings persisted securely (API keys in macOS Keychain)
9. Launches at login, lives quietly in menu bar

## Non-Goals (out of scope v1)

- Windows / Linux support
- iOS / iPadOS
- Syncing prompts across machines
- Team sharing
- Paid distribution / App Store
- Voice input
- Image input

---

## Target User
Single developer (personal internal tool). No multi-user concerns.

## macOS Minimum Version
macOS 15 Sequoia

Rationale: macOS 15 gives us `@Observable` (no `ObservableObject` boilerplate),
the latest SwiftUI layout APIs, `SMAppService` for login items, and the full
Swift concurrency model without workarounds. The user confirmed macOS 15+.

## Language & Tooling
| Tool | Version | Notes |
|------|---------|-------|
| Swift | 5.10+ | macOS 15 SDK ships with Swift 5.10 |
| Xcode | 16+ | Required for macOS 15 deployment target |
| SwiftUI | Latest (macOS 15+) | |
| Swift Package Manager | For all dependencies | |
| XCTest | Unit + integration tests | |
| SwiftLint | Linting (enforced in CI) | |
| Node.js | Bundled v20 LTS universal binary | Sidecar only — NOT a user install requirement |

> **Swift 6 Strict Concurrency:** Set `SWIFT_STRICT_CONCURRENCY = complete` in
> build settings from day one. All code must compile with zero data-race warnings.
> `@MainActor` on all `AppState` mutating methods and all UI-touching code.
> `Sendable` on all value types crossing actor boundaries.

## App Entitlements
```xml
<!-- AITextTool.entitlements -->
<key>com.apple.security.app-sandbox</key>
<false/>
<!-- Sandbox MUST be off — required for AX API, CGEventTap, Keychain access -->

<key>com.apple.security.network.client</key>
<true/>
<!-- Outbound HTTP for AI provider calls -->
```

## Info.plist Additions
```xml
<key>NSAccessibilityUsageDescription</key>
<string>AITextTool reads selected text from other apps to send to AI.</string>

<key>LSUIElement</key>
<true/>
<!-- Agent app — no Dock icon, lives in menu bar only -->
```

---

## Dependency List (Swift Packages)

| Package | URL | Purpose |
|---------|-----|---------|
| KeyboardShortcuts | https://github.com/sindresorhus/KeyboardShortcuts | Hotkey recorder UI widget in Settings |
| Sparkle | https://github.com/sparkle-project/Sparkle | Auto-update framework (v2.6+) |

> **LaunchAtLogin is NOT a dependency.** macOS 15 ships `SMAppService` natively.
> Use `SMAppService.mainApp.register()` / `.unregister()` directly — no package needed.
>
> Keep dependencies minimal. Prefer stdlib and Foundation. No Alamofire, no RxSwift.
> Every dependency must be justified in a comment at its import site.

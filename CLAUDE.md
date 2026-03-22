# CLAUDE.md — Prompty (prompty)

## Project Overview

Prompty is a macOS menu bar app that captures selected text system-wide via a global hotkey, sends it to an AI provider with a chosen prompt, streams the result in a floating panel, and lets the user replace the original text, copy, diff, or continue chatting.

**Status:** Pre-implementation. The `docs/` folder contains the complete specification (21 files). No application code exists yet.

## Tech Stack

- **Language:** Swift 5.10+, SwiftUI (macOS 15+ / Sequoia minimum)
- **IDE:** Xcode 16+
- **Dependencies:** KeyboardShortcuts (hotkey recorder), Sparkle (auto-update)
- **Package manager:** Swift Package Manager
- **Testing:** XCTest
- **Linting:** SwiftLint (strict mode, zero warnings enforced)
- **Concurrency:** Swift 6 strict concurrency (`SWIFT_STRICT_CONCURRENCY = complete`)

## Spec Files

All specification lives in `docs/`. Read `docs/00_INDEX.md` for the full index. Key files:

- `01_PROJECT_OVERVIEW.md` — Vision, goals, stack, entitlements
- `02_GITFLOW.md` — Branch strategy, commit conventions, PR rules
- `03_AGENT_PROTOCOL.md` — Agent roles (Feature, Review, Fix, Merge)
- `04_ARCHITECTURE.md` — System design, folder structure, DI rules, AppState
- `12_TESTING.md` — Testing strategy and required test names
- `13_REVIEW_CHECKLIST.md` — Review gate (50 items)
- `14_BUILD_PLAN.md` — Week-by-week implementation plan

## Key Conventions

### Git
- **Branch model:** GitFlow — `main` (releases) <- `develop` (integration) <- `feature/`, `fix/`, `chore/`, `test/`
- **Always branch off `develop`**, never `main`
- **Commit format:** Conventional Commits — `type(scope): description`
  - Types: `feat`, `fix`, `test`, `refactor`, `chore`, `docs`, `style`, `perf`
  - Scopes: `hotkey`, `text-capture`, `ai`, `prompts`, `ui`, `settings`, `sidecar`
- **Squash merge** feature branches into develop
- **Rebase onto develop** before opening for review

### Architecture
- `@Observable` singleton `AppState` is the single source of truth
- All `AppState` mutations must happen on `@MainActor`
- Protocol-first design — depend on protocols, not concrete types
- Dependency injection via initializer (no service locators or direct singleton access in testable code)
- Value types preferred over classes
- `AsyncThrowingStream` for AI streaming
- Typed `AppError` enum — no stringly-typed errors

### Code Style
- No hardcoded user-facing strings — use `Strings.swift`
- Sandbox is OFF (required for AX API, CGEventTap, Keychain)
- `LSUIElement = true` (menu bar agent app, no Dock icon)
- Keep dependencies minimal — prefer stdlib and Foundation

## Commands

```bash
# Build
xcodebuild build -scheme Prompty -destination 'platform=macOS'

# Test
xcodebuild test -scheme Prompty -destination 'platform=macOS'

# Lint
swiftlint lint --strict
```

## Custom Skills (Slash Commands)

Project-specific skills in `.claude/commands/`:

| Command | Description |
|---------|-------------|
| `/feature <description>` | Spec-aware Feature Agent — reads all docs, creates branch off develop, implements per spec with tests |
| `/review [branch]` | Review Agent — runs the full 50-item checklist against the current or specified branch |
| `/fix <issues>` | Fix Agent — reads review failures and fixes only the flagged items |
| `/build` | Build & Test — runs xcodebuild build + test + swiftlint, reports summary |

Global skills also available: `/branch`, `/pr`, `/senior-review`, `/commit`

## MCP Servers

Configured in `.claude/settings.local.json`:

- **Playwright** — Browser automation and E2E testing
- **Fetch** — HTTP requests to external APIs (useful for testing AI provider endpoints)
- **Sequential Thinking** — Structured multi-step reasoning for complex problems
- **Context7** — Up-to-date library documentation lookup (global plugin)

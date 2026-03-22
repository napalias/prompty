# 13 — Review Checklist

> This is the definitive checklist the Review Agent runs against every PR.
> A single FAIL on any item = REVIEW_AGENT_RESULT: FAIL
> All items must be PASS for REVIEW_AGENT_RESULT: PASS

---

## Section A: Tests

- [ ] **A1** `xcodebuild test` exits with code 0 (all tests pass)
- [ ] **A2** Every new public method on a service/repository has at least one test
- [ ] **A3** No test uses `Thread.sleep`, `Task.sleep` with a hardcoded value, or `DispatchQueue.asyncAfter` with a hardcoded duration — all timing is injected
- [ ] **A4** No test accesses the real filesystem, real Keychain, real network, or real AX API
- [ ] **A5** Test coverage for all changed service files is ≥ 80% (check `.xcresult` coverage report)
- [ ] **A6** Test names follow the `test_<method>_<condition>_<result>` convention

---

## Section B: Linting & Style

- [ ] **B1** `swiftlint lint --strict` exits with 0 warnings, 0 errors
- [ ] **B2** No `// swiftlint:disable` comments added (unless already in `.swiftlint.yml`)
- [ ] **B3** No `print()` calls in production code — use `Logger.swift` wrapper
- [ ] **B4** No `TODO:` or `FIXME:` comments left in production code
- [ ] **B5** No commented-out code blocks
- [ ] **B6** All files end with a newline
- [ ] **B7** Any animation checks `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` — no animation runs unconditionally (see 19Q)
- [ ] **B8** Code comments follow policy in `19_FINAL_GAPS.md` §19S: WHY not WHAT, `// MARK:` sections present in files >80 lines, `///` on all public protocol methods

---

## Section C: Architecture Compliance

- [ ] **C1** No concrete type used where a protocol is defined (check all `init` parameters of services)
- [ ] **C2** `AppState` is the only `@Observable` class in the app; no view has its own `@State` for shared data
- [ ] **C3** No service, repository, or manager creates its own dependencies — all injected via `init`
- [ ] **C4** No `URLSession.shared` used directly — must be injected
- [ ] **C5** No new files added outside the folder structure defined in `04_ARCHITECTURE.md`
- [ ] **C6** No logic in SwiftUI View bodies — views only read `AppState` and call methods on injected controllers/services
- [ ] **C7** `Prompt`, `AIMessage`, `AIRequest`, `AppSettings`, `HotkeySetting` are `struct`, not `class`
- [ ] **C8** `AppError` is the only error type thrown from services — no raw `NSError` or `URLError` propagated to callers

---

## Section D: DRY & Code Quality

- [ ] **D1** No logic duplicated across two or more files — if similar code appears twice, it must be extracted
- [ ] **D2** No magic strings in logic (URLs, key names, model IDs) — all in named constants or enums
- [ ] **D3** No magic numbers in logic — all in named constants
- [ ] **D4** No force unwraps (`!`) in production code except where explicitly justified with a comment
- [ ] **D5** No `try!` in production code
- [ ] **D6** No `as!` in production code except in AX API calls (which are inherently untyped) with a comment
- [ ] **D7** Functions are ≤ 40 lines. Longer functions must be refactored.
- [ ] **D8** No file exceeds 250 lines (excluding tests). Must be split.

---

## Section E: GitFlow

- [ ] **E1** Branch name follows convention: `feature/`, `fix/`, `chore/`, `test/`
- [ ] **E2** Branch is off `develop`, not `main`
- [ ] **E3** All commit messages follow Conventional Commits format
- [ ] **E4** No merge commits in branch history (rebase onto develop if needed)
- [ ] **E5** PR description contains all required sections (What / Why / How / Test Coverage / Checklist)
- [ ] **E6** Branch is not stale — `git merge-base --is-ancestor origin/develop HEAD` exits 0; if not, agent must rebase first

---

## Section F: Security

- [ ] **F1** No API keys, tokens, or credentials hardcoded or in any tracked file
- [ ] **F2** All API keys read from `KeychainService`, not `UserDefaults`
- [ ] **F3** No user text logged at any log level
- [ ] **F4** Network requests use HTTPS only (no `http://` except `localhost` for Ollama)

---

## Section G: Performance

- [ ] **G1** No work on the main thread that takes >16ms (no synchronous network calls, no synchronous file I/O on main thread)
- [ ] **G2** `@MainActor` used correctly — only UI-touching code is `@MainActor`
- [ ] **G3** `AsyncThrowingStream` continuations always have a `onTermination` handler to cancel in-flight work
- [ ] **G4** `AppState` mutating methods are marked `@MainActor` — no mutation from background actors
- [ ] **G5** No `UserDefaults.standard` accessed outside `SettingsRepository` — all settings reads/writes go through the repository

---

## Section H: Completeness

- [ ] **H1** `NSStatusItem` icon is set as template image (`nsImage.isTemplate = true`)
- [ ] **H2** All user-facing strings use `Strings.swift` constants — no hardcoded English strings in view files
- [ ] **H3** SwiftUI previews use `PreviewData.swift` mock data — no hardcoded literals in `#Preview` blocks
- [ ] **H4** `Package.resolved` is committed in the same commit as any `Package.swift` change
- [ ] **H5** No `SMAppService` functionality wrapped in an external package — use `SMAppService` directly

---

## How the Review Agent Runs This Checklist

```
For each item:
  1. Run the relevant check (compile, lint, grep, diff analysis)
  2. Mark PASS or FAIL with file:line evidence
  
Output summary:
  PASS count: N
  FAIL count: N
  
If FAIL count > 0:
  REVIEW_AGENT_RESULT: FAIL
  [list all failures with file:line]
Else:
  REVIEW_AGENT_RESULT: PASS
```

### Automated Checks (run commands)

```bash
# A1
xcodebuild test -scheme AITextTool -destination 'platform=macOS'

# B1
swiftlint lint --strict

# B3 — no print() in production code
grep -rn "print(" AITextTool/ --include="*.swift" \
  | grep -v "// " | grep -v "AITextToolTests/"

# B4 — no TODOs
grep -rn "TODO:\|FIXME:" AITextTool/ --include="*.swift" \
  | grep -v "AITextToolTests/"

# B5 — no commented-out code (heuristic)
grep -rn "^[[:space:]]*//" AITextTool/ --include="*.swift" \
  | grep -v "MARK:\|swiftlint\|///" | head -20

# D4 — force unwraps
grep -rn "[^!]![^=!]" AITextTool/ --include="*.swift" \
  | grep -v "AITextToolTests/" | grep -v "// justified"

# F4 — no plain http (except localhost)  
grep -rn '"http://' AITextTool/ --include="*.swift" \
  | grep -v \"localhost\"

# G4 — AppState mutations must be @MainActor
grep -rn "func.*state\." AITextTool/ --include="*.swift" \
  | grep -v "@MainActor\|// justified\|AITextToolTests/"

# G5 — no UserDefaults.standard outside SettingsRepository
grep -rn "UserDefaults.standard" AITextTool/ --include="*.swift" \
  | grep -v "SettingsRepository.swift"

# H1 — NSStatusItem icon must be template
grep -rn "statusItem\|NSStatusItem" AITextTool/ --include="*.swift" \
  | grep -v "isTemplate = true\|AITextToolTests/"

# E6 — branch is not stale
git merge-base --is-ancestor origin/develop HEAD
```

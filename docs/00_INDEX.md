# AITextTool — Master Specification Index (v5)

> Feed this entire `/spec` folder to Claude Code at the start of every agent session.
> Each agent MUST read ALL files in this folder before writing a single line of code.

## File Order (read in sequence)

| # | File | Purpose |
|---|------|---------|
| 01 | `01_PROJECT_OVERVIEW.md` | Vision, goals, non-goals, stack, entitlements |
| 02 | `02_GITFLOW.md` | Branch strategy, commit conventions, PR rules |
| 03 | `03_AGENT_PROTOCOL.md` | How agents spawn, communicate, hand off, loop |
| 04 | `04_ARCHITECTURE.md` | Full system design, patterns, folder structure, DI rules |
| 05-07 | `05_06_07_MODULES_HOTKEY_CAPTURE_REPLACE.md` | Hotkey, text capture, text replace |
| 08 | `08_MODULE_AI_PROVIDERS.md` | Provider protocol + all provider implementations |
| 09-11 | `09_10_11_MODULES_PROMPTS_UI_SETTINGS.md` | Prompts, all UI views, settings + keychain |
| 12 | `12_TESTING.md` | Testing strategy, all required test names, coverage rules |
| 13 | `13_REVIEW_CHECKLIST.md` | Review gate — must all pass before any PR merges |
| 14 | `14_BUILD_PLAN.md` | Week-by-week tasks, agent prompts, dependency order |
| 15 | `15_CI_CD.md` | GitHub Actions workflows, coverage script, branch protection |
| 16 | `16_EDGE_CASES.md` | Cancel streaming, secure input, long text, multi-monitor |
| 17 | `17_UPDATES_CRASHREPORTING_HISTORY.md` | Sparkle, local crash logs, session history |
| 18 | `18_CRITICAL_GAPS.md` | Node bundling, hotkey re-fire, undo, validation, SwiftLint config, telemetry policy |
| 19 | `19_FINAL_GAPS.md` | macOS 15 fix, sleep/wake, single instance, timeouts, markdown rendering, token counter, Myers diff, missing build tasks |
| 20 | `20_REMAINING_GAPS.md` | Swift 6 concurrency, universal Node binary, pipe deadlock fix, template injection, edit-before-replace, recently-used prompts, loading state, Strings.swift, PreviewData, Logger categories, build number, offline handling, dark mode |
| 21 | `21_PROMPT_EDITING_AND_AUDIT_FIXES.md` | In-panel prompt editing (pencil+sheet+plus), copy-on-edit for built-ins, SwiftData history, focus/keyboard fix, no-provider state, JSON decode resilience, sidecar orphan prevention, final PanelMode enum | | Swift 6 concurrency, universal Node binary, pipe deadlock fix, template injection, edit-before-replace, recently-used prompts, loading state, Strings.swift, PreviewData, Logger categories, build number, offline handling, dark mode |

## Quick Agent Commands

```
# Start new feature agent
"Read all files in /spec in order (00_INDEX through 21_PROMPT_EDITING_AND_AUDIT_FIXES),
 then implement [FEATURE] per the spec. Do not write code until all files are read."

# Start review agent
"Read /spec/13_REVIEW_CHECKLIST.md, /spec/12_TESTING.md, and /spec/15_CI_CD.md.
 Also read /spec/19_FINAL_GAPS.md sections 19Q and 19S for two new checklist items.
 Review the diff on branch [BRANCH] against develop. Output PASS or FAIL with reasons."

# Start fix agent (after failed review)
"Read /spec/13_REVIEW_CHECKLIST.md. The review agent flagged these issues: [ISSUES].
 Fix them on branch [BRANCH]. Do not change anything outside the flagged issues."

# Start merge agent (after PASS)
"Squash-merge branch [BRANCH] into develop, delete the branch, push."
```

## Spec Coverage Map

| Concern | Covered In |
|---------|-----------|
| Xcode project setup | 01, 04 |
| macOS 15 minimum version | 01, 19A |
| GitFlow + commits | 02 |
| Agent roles + loop | 03 |
| Folder structure + DI | 04 |
| Hotkey (CGEventTap) | 05-07 |
| Sleep/wake re-registration | 19B |
| Single instance enforcement | 19C |
| AX text capture + clipboard fallback | 05-07 |
| Secure input detection | 16B |
| Long text truncation | 16C |
| Text replace + undo policy | 05-07, 18E |
| Paste mode (plain vs rich) | 19H |
| Claude API key mode | 08 |
| Claude OAuth (subscription) + Node bundle | 08, 18A |
| OAuth token expiry handling | 19D |
| OpenAI API | 08 |
| OpenAI-compatible custom base URL | 19J |
| Groq / LM Studio quick-fill | 19J |
| Ollama local + model-not-found error | 08, 18I |
| Cancel streaming (Escape) | 16A |
| App quit while streaming | 19F |
| Auto-copy on panel dismiss | 19G |
| Request timeouts | 19E |
| Retry logic (5xx only) | 19L |
| SSE parser | 08 |
| Default system prompt | 19K |
| Prompt model + validation | 09-11, 18F |
| Prompt paste mode per-prompt | 19H |
| Prompt render mode per-prompt | 19I |
| Built-in prompt library (10 prompts) | 09-11 |
| Prompt import/export schema | 18H |
| Floating panel + multi-monitor | 09-11, 16D |
| Panel height clamping | 19N |
| Panel fullscreen Z-order fix | 19P |
| Reduce motion support | 19Q |
| Action bar (Enter/⌘Enter/D) | 09-11 |
| Result render modes (plain/md/code) + toggle | 19I |
| Token counter + cost estimate | 19M |
| Diff view (Myers word-level) | 09-11, 19R |
| Continue chat | 09-11 |
| Error view (all AppError cases) | 04, 18C |
| No-text-selected toast | 19O |
| Settings UI (4 tabs incl. Logs) | 09-11, 17B |
| Keychain storage | 09-11 |
| First-launch onboarding | 18D |
| Hotkey re-fires while panel open | 18B |
| Source app closes while panel open | 18C |
| Session history persistence | 17C |
| Crash reporting (local only) | 17B |
| Sparkle auto-update | 17A |
| SwiftLint configuration | 18G |
| Code comments policy | 19S |
| Telemetry policy | 18J |
| Testing strategy + all test names | 12 |
| Review checklist (35 + 2 new items) | 13, 19Q, 19S |
| GitHub Actions CI/CD | 15 |
| Coverage enforcement script | 15 |
| .gitignore complete definition | 19T |
| ExportOptions.plist | 19U |
| README.md required contents | 19V |
| Build plan + agent task prompts | 14 |
| Week 5 tasks (CI, onboarding, history, Sparkle, stability) | 19W |
| Week 5 tasks W5-7, W5-8 (Strings, PreviewData, Logger, Performance) | 20V |
| Swift 6 strict concurrency rules | 20A |
| Universal Node.js binary | 20D |
| Sidecar pipe deadlock prevention | 20F |
| Atomic write for all repositories | 20G |
| Template injection prevention | 20H |
| Edit-before-replace view | 20I |
| Recently-used prompts | 20J |
| Loading shimmer (first token latency) | 20K |
| NSStatusItem template image | 20L |
| Build number auto-increment | 20M |
| Strings.swift all constants | 20N |
| PreviewData.swift mock data | 20O |
| Logger subsystem + categories | 20P |
| Settings ⌘, keyboard shortcut | 20Q |
| Notarization guide | 20R |
| Offline / no-network behaviour | 20S |
| Dark mode panel appearance | 20T |
| Package.resolved commit rule | 20U |
| AppState.reset() full implementation | 20W |
| Review checklist now 50 items | 13, 20X |
| In-panel prompt editing (pencil icon + sheet) | 21A |
| Built-in copy-on-edit (personal copy, hide original) | 21A |
| Create prompt from panel (+ button) | 21A |
| PromptRepository.hide() / unhide() | 21A |
| Complete Prompt model (all fields) | 21A |
| SwiftData session history | 21B |
| @Observable rule clarification (view-local allowed) | 21C |
| Keyboard routing fix (canBecomeKey + source app re-activate) | 21D |
| No-provider fresh-install state | 21E |
| JSON decode resilience with backup | 21F |
| Model staleness + ModelConstants | 21G |
| Sidecar orphan process prevention | 21H |
| Definitive PanelMode enum | 21K |

> Feed this entire `/spec` folder to Claude Code at the start of every agent session.
> Each agent MUST read ALL files in this folder before writing a single line of code.

## File Order (read in sequence)

| # | File | Purpose |
|---|------|---------|
| 01 | `01_PROJECT_OVERVIEW.md` | Vision, goals, non-goals, stack, entitlements |
| 02 | `02_GITFLOW.md` | Branch strategy, commit conventions, PR rules |
| 03 | `03_AGENT_PROTOCOL.md` | How agents spawn, communicate, hand off, loop |
| 04 | `04_ARCHITECTURE.md` | Full system design, patterns, folder structure, DI rules |
| 05-07 | `05_06_07_MODULES_HOTKEY_CAPTURE_REPLACE.md` | Hotkey, text capture, text replace |
| 08 | `08_MODULE_AI_PROVIDERS.md` | Provider protocol + all provider implementations |
| 09-11 | `09_10_11_MODULES_PROMPTS_UI_SETTINGS.md` | Prompts, all UI views, settings + keychain |
| 12 | `12_TESTING.md` | Testing strategy, all required test names, coverage rules |
| 13 | `13_REVIEW_CHECKLIST.md` | 35-item gate — must all pass before any PR merges |
| 14 | `14_BUILD_PLAN.md` | Week-by-week tasks, agent prompts, dependency order |
| 15 | `15_CI_CD.md` | GitHub Actions workflows, coverage script, branch protection |
| 16 | `16_EDGE_CASES.md` | Cancel streaming, secure input, long text, multi-monitor |
| 17 | `17_UPDATES_CRASHREPORTING_HISTORY.md` | Sparkle, local crash logs, session history |
| 18 | `18_CRITICAL_GAPS.md` | Node bundling, hotkey re-fire, undo, validation, SwiftLint config, telemetry policy |

## Quick Agent Commands

```
# Start new feature agent
"Read all files in /spec in order (00_INDEX through 21_PROMPT_EDITING_AND_AUDIT_FIXES),
 then implement [FEATURE] per the spec. Do not write code until all files are read."

# Start review agent
"Read /spec/13_REVIEW_CHECKLIST.md, /spec/12_TESTING.md, and /spec/15_CI_CD.md.
 Review the diff on branch [BRANCH] against develop. Output PASS or FAIL with reasons."

# Start fix agent (after failed review)
"Read /spec/13_REVIEW_CHECKLIST.md. The review agent flagged these issues: [ISSUES].
 Fix them on branch [BRANCH]. Do not change anything outside the flagged issues."

# Start merge agent (after PASS)
"Squash-merge branch [BRANCH] into develop, delete the branch, push."
```


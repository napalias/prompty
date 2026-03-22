# AITextTool — How to Start with Claude Code
## Multi-Agent, Multi-Branch Practical Guide

---

## What You Need Before Starting

```
✅ macOS 15 machine
✅ Xcode 16 installed
✅ Homebrew installed
✅ GitHub account
✅ GitHub CLI installed: brew install gh
✅ Git configured: git config --global user.name / user.email
✅ Claude Code installed: npm install -g @anthropic-ai/claude-code
✅ Claude Code logged in: claude login
✅ This /spec folder on your machine (download from outputs)
```

---

## PHASE 0 — One-Time Human Setup (30 minutes, you do this, not agents)

These steps cannot be delegated. Do them once before any agent runs.

### Step 0-1: Create GitHub repo

```bash
# Create private repo
gh repo create AITextTool --private --clone
cd AITextTool

# Create develop branch as default
git checkout -b develop
git commit --allow-empty -m "chore: initial repository setup"
git push -u origin develop

# Set develop as default branch on GitHub
gh repo edit --default-branch develop
```

### Step 0-2: Copy spec folder into repo

```bash
# Put the entire /spec folder at the root of the repo
cp -r /path/to/your/spec ./spec

git add spec/
git commit -m "chore: add project specification"
git push origin develop
```

### Step 0-3: Protect develop branch (stops agents pushing directly)

```bash
gh api repos/:owner/AITextTool/branches/develop/protection \
  --method PUT \
  --input - << 'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["Test & Lint"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null
}
EOF
```

### Step 0-4: Create Xcode project manually

> ⚠️ Do this by hand — Xcode project creation via command line is fragile.
> Agents will add files to it, but you create the skeleton.

1. Open Xcode → File → New → Project
2. Choose **macOS → App**
3. Settings:
   - Product Name: `AITextTool`
   - Bundle Identifier: `com.yourname.AITextTool`
   - Language: **Swift**
   - Interface: **SwiftUI**
   - Uncheck "Include Tests" (agents will add the test target)
4. Save into your cloned `AITextTool/` folder
5. Add a second target: File → New → Target → **Unit Testing Bundle**
   - Name: `AITextToolTests`

6. In **Signing & Capabilities**:
   - Remove "App Sandbox" capability (click the `–` button)
   - Add "Hardened Runtime" capability
   - Check "Disable Library Validation"

7. Set deployment target: **macOS 15.0** in both targets

8. In **Build Settings** (AITextTool target):
   - Search `SWIFT_STRICT_CONCURRENCY` → set to `complete`
   - Search `CURRENT_PROJECT_VERSION` → set to `1`

9. Commit the empty project:

```bash
git add AITextTool.xcodeproj/
git commit -m "chore: create Xcode project skeleton"
git push origin develop
```

### Step 0-5: Add .gitignore

```bash
cat > .gitignore << 'EOF'
*.xcuserstate
xcuserdata/
DerivedData/
*.xcresult
*.xcarchive
.DS_Store
.build/
AITextTool/Sidecar/node
AITextTool/Sidecar/node_modules/
coverage.json
Export/
*.dmg
sparkle_private.pem
.env
*.log
EOF

git add .gitignore
git commit -m "chore: add gitignore"
git push origin develop
```

---

## PHASE 1 — Understanding Claude Code Agent Modes

Claude Code has two ways to run. Use the right one for each situation.

### Mode A: Interactive (you watch, can intervene)

```bash
claude
```

Opens an interactive REPL. You paste the task prompt, watch it work,
can ask questions or correct mistakes in real time.
**Use for:** Week 1 tasks, anything you want to watch closely.

### Mode B: Headless / non-interactive (fire and forget)

```bash
claude --print "your task prompt here" > agent_output.log 2>&1
```

Runs, produces output to a log file, exits.
**Use for:** Week 2+ parallel tasks you run simultaneously in separate terminals.

### Mode C: With a task file (long prompts)

```bash
# Write prompt to file first
cat > task.md << 'EOF'
[your full task prompt]
EOF

# Run with the file
claude --print "$(cat task.md)" > output.log 2>&1
```

**Use for:** Feature agent prompts (they're long — easier from file than inline).

---

## PHASE 2 — The Master Agent Prompt Template

Every agent session starts with this. Fill in `[TASK]` and `[BRANCH]`.

```
You are working on AITextTool, a macOS menu bar app.

FIRST: Read every file in the ./spec folder in this exact order:
00_INDEX.md, 01_PROJECT_OVERVIEW.md, 02_GITFLOW.md, 03_AGENT_PROTOCOL.md,
04_ARCHITECTURE.md, 05_06_07_MODULES_HOTKEY_CAPTURE_REPLACE.md,
08_MODULE_AI_PROVIDERS.md, 09_10_11_MODULES_PROMPTS_UI_SETTINGS.md,
12_TESTING.md, 13_REVIEW_CHECKLIST.md, 14_BUILD_PLAN.md, 15_CI_CD.md,
16_EDGE_CASES.md, 17_UPDATES_CRASHREPORTING_HISTORY.md,
18_CRITICAL_GAPS.md, 19_FINAL_GAPS.md, 20_REMAINING_GAPS.md,
21_PROMPT_EDITING_AND_AUDIT_FIXES.md

Do NOT write any code until you have read ALL of these files.

TASK: [PASTE TASK DESCRIPTION FROM BUILD PLAN]

BRANCH: [BRANCH NAME — create from develop if it doesn't exist]

CONSTRAINTS:
- Only implement what is described in the task. Nothing extra.
- Every new public method must have at least one test.
- Follow all rules in 13_REVIEW_CHECKLIST.md proactively before committing.
- Commit with conventional commit format after completing the work.
- Push the branch when done.

When finished, output exactly:
FEATURE_AGENT_DONE
branch: [branch name]
commits: [N]
tests_added: [N]
files_changed: [list of files]
```

---

## PHASE 3 — Review Agent Prompt Template

Run this after every Feature Agent finishes.

```
You are the Review Agent for AITextTool.

Read these spec files first:
- ./spec/13_REVIEW_CHECKLIST.md
- ./spec/12_TESTING.md
- ./spec/04_ARCHITECTURE.md
- ./spec/21_PROMPT_EDITING_AND_AUDIT_FIXES.md (section 21J for latest checklist items)

Your job is to review the branch [BRANCH NAME] against develop.

Run these commands in sequence:
1. git fetch origin
2. git checkout [BRANCH NAME]
3. xcodebuild test -scheme AITextTool -destination 'platform=macOS' -enableCodeCoverage YES -resultBundlePath TestResults.xcresult 2>&1 | tail -50
4. swiftlint lint --strict 2>&1
5. git diff origin/develop...[BRANCH NAME] 2>&1

Then check every item in 13_REVIEW_CHECKLIST.md against what you see.

Output exactly:
REVIEW_AGENT_RESULT: PASS   (if all 50 items pass)
branch: [branch name]

OR:

REVIEW_AGENT_RESULT: FAIL
branch: [branch name]
issues:
  - [FILE:LINE] description
test_failures:
  - TestName: failure message
lint_warnings:
  - file:line: rule: message
```

---

## PHASE 4 — Fix Agent Prompt Template

Run after a FAIL result. Paste the failure output directly.

```
You are the Fix Agent for AITextTool.

Read: ./spec/13_REVIEW_CHECKLIST.md

The Review Agent found these issues on branch [BRANCH]:
[PASTE THE FULL FAIL OUTPUT FROM REVIEW AGENT]

Fix ONLY the listed issues. Do not change anything else.
Each fix should be a separate commit: fix(scope): what was fixed

When done, output:
FIX_AGENT_DONE
branch: [branch name]
fixes_applied: [N]
iteration: [N]
```

---

## PHASE 5 — Merge Agent Prompt Template

Run after a PASS result.

```
You are the Merge Agent for AITextTool.

Squash-merge branch [BRANCH] into develop:

git checkout develop
git pull origin develop
git merge --squash [BRANCH]
git commit -m "[CONVENTIONAL COMMIT MESSAGE SUMMARISING THE PR]"
git push origin develop
git push origin --delete [BRANCH]
git branch -d [BRANCH]

Output:
MERGE_AGENT_DONE: [BRANCH] merged into develop
```

---

## PHASE 6 — Week-by-Week Execution Plan

### WEEK 1 — Run these yourself, one at a time, watch closely

These are sequential — each depends on the previous.

---

#### W1-1: Project Setup (run this first, alone)

```bash
mkdir -p tasks
cat > tasks/W1-1.md << 'EOF'
[Paste the full master template above, with this task:]

TASK: Implement Task W1-1 from spec/14_BUILD_PLAN.md exactly.
Create the full folder structure from 04_ARCHITECTURE.md.
Create placeholder .swift files for every file listed.
Add SwiftLint SPM plugin and .swiftlint.yml from spec 18G.
Add all AppError cases from 04_ARCHITECTURE.md.
Add Logger.swift from spec 20P.
Add Strings.swift from spec 20N (all constants).
Add PreviewData.swift from spec 20O.
Add ModelConstants.swift from spec 21G.
The project must compile with zero errors after this task.

BRANCH: chore/xcode-project-setup
EOF

claude "$(cat tasks/W1-1.md)"
```

Wait for `FEATURE_AGENT_DONE`. Then run Review Agent. Then Merge Agent.

---

#### W1-2: AppState + AppDelegate + MenuBar

```bash
cat > tasks/W1-2.md << 'EOF'
[Master template with:]

TASK: Implement Task W1-2 from spec/14_BUILD_PLAN.md.
Implement AppState.swift (@Observable @MainActor) with the COMPLETE
definition from 04_ARCHITECTURE.md and 21K (PanelMode enum).
Implement AppDelegate.swift, AITextToolApp.swift, MenuBarController.swift.
Wire SMAppService for launch-at-login (NOT LaunchAtLogin package).
The app must launch, show a menu bar icon, and quit cleanly.

BRANCH: feature/app-foundation
EOF

claude "$(cat tasks/W1-2.md)"
```

---

### WEEK 2 — Run these in PARALLEL (5 separate terminal windows)

Open 5 terminal tabs. Run one command in each. They are independent.

**Terminal 1 — W2-1:**
```bash
cat > tasks/W2-1.md << 'EOF'
[Master template with:]
TASK: Implement Task W2-1 from spec/14_BUILD_PLAN.md.
Read spec sections 05 (HotkeyManager) from 05_06_07_MODULES file.
Read spec 20C (hotkey registration failure handling).
Implement HotkeyManagerProtocol.swift, HotkeyManager.swift,
MockHotkeyManager.swift, HotkeyManagerTests.swift.
All tests from 12_TESTING.md HotkeyManager section must pass.
BRANCH: feature/hotkey-manager
EOF
claude "$(cat tasks/W2-1.md)" > logs/W2-1.log 2>&1 &
```

**Terminal 2 — W2-2:**
```bash
cat > tasks/W2-2.md << 'EOF'
[Master template with:]
TASK: Implement Task W2-2 from spec/14_BUILD_PLAN.md.
Read spec section 06 from 05_06_07_MODULES file.
Read spec 16B (secure input), 16C (long text), 20E (clipboard race condition).
Implement TextCaptureService + AccessibilityReader + ClipboardFallbackReader
+ PermissionChecker + SecureInputDetector + all tests.
BRANCH: feature/text-capture
EOF
claude "$(cat tasks/W2-2.md)" > logs/W2-2.log 2>&1 &
```

**Terminal 3 — W2-3:**
```bash
cat > tasks/W2-3.md << 'EOF'
[Master template with:]
TASK: Implement Task W2-3 from spec/14_BUILD_PLAN.md.
Read spec section 07 from 05_06_07_MODULES file.
Read spec 21D (source app re-activation before paste).
Implement TextReplaceService + AccessibilityWriter + ClipboardPasteWriter + all tests.
BRANCH: feature/text-replace
EOF
claude "$(cat tasks/W2-3.md)" > logs/W2-3.log 2>&1 &
```

**Terminal 4 — W2-4:**
```bash
cat > tasks/W2-4.md << 'EOF'
[Master template with:]
TASK: Implement Task W2-4 from spec/14_BUILD_PLAN.md.
Read spec 08_MODULE_AI_PROVIDERS.md fully.
Read spec 19E (timeouts), 19J (custom base URL), 19K (default system prompt),
19L (retry), 19M (token counter), 20F (sidecar pipe), 21G (model constants).
Implement all providers + SSEParser + AIProviderManager + all tests.
Do NOT implement AnthropicOAuthProvider (that is W3-2).
BRANCH: feature/ai-providers
EOF
claude "$(cat tasks/W2-4.md)" > logs/W2-4.log 2>&1 &
```

**Terminal 5 — W2-5 + W2-6 (sequential, same terminal):**
```bash
# W2-5 first
cat > tasks/W2-5.md << 'EOF'
[Master template with:]
TASK: Implement Task W2-5 from spec/14_BUILD_PLAN.md.
Read spec section 09 from 09_10_11 file.
Read spec 18F (validation), 18H (export schema), 20J (recently used),
21A (complete Prompt model with all fields).
Implement Prompt.swift (complete model), BuiltInPrompts.swift,
PromptRepository (JSON storage with hide/unhide/recordUsage),
PromptRepositoryProtocol, MockPromptRepository + all tests.
BRANCH: feature/prompt-store
EOF
claude "$(cat tasks/W2-5.md)" > logs/W2-5.log 2>&1

# Wait, review, merge, then W2-6
cat > tasks/W2-6.md << 'EOF'
[Master template with:]
TASK: Implement Task W2-6 from spec/14_BUILD_PLAN.md.
Read spec section 11 from 09_10_11 file.
Read spec 20U (Package.resolved rule), 21F (decode resilience).
Implement AppSettings, SettingsRepository (inject UserDefaults),
KeychainService, all protocols, all mocks, all tests.
Use decode resilience pattern from 21F in SettingsRepository.
BRANCH: feature/settings-core
EOF
claude "$(cat tasks/W2-6.md)" > logs/W2-6.log 2>&1
```

**Watch logs in real time:**
```bash
# In a separate terminal, watch all logs
tail -f logs/W2-*.log
```

**After all W2 agents finish**, run Review → Fix → Merge loop for each branch.
Merge them in this order to avoid conflicts:
```
W2-1 → W2-2 → W2-3 → W2-4 → W2-5 → W2-6
```

---

### WEEK 3 — Mostly sequential (UI depends on Week 2)

**W3-1 first (floating panel — everything depends on this):**
```bash
cat > tasks/W3-1.md << 'EOF'
[Master template with:]
TASK: Implement Task W3-1 from spec/14_BUILD_PLAN.md.
Read spec section 10 from 09_10_11 file.
Read spec 16D (multi-monitor), 19N (height clamp), 19O (toast),
19P (fullscreen Z-order), 19Q (reduce motion), 20K (loading shimmer),
20L (menu bar icon), 21D (canBecomeKey + focus fix),
21E (no-provider state), 21K (complete PanelMode).
Implement ALL views listed in 04_ARCHITECTURE.md UI/Views folder.
Wire AppState to FloatingPanelController.
Wire HotkeyManager: hotkey → capture → show panel.
SwiftUI #Preview blocks required for every view using PreviewData.swift.
BRANCH: feature/floating-panel
EOF
claude "$(cat tasks/W3-1.md)"
```

**W3-2 and W3-3 in parallel after W3-1 merges:**

```bash
# Terminal 1
cat > tasks/W3-2.md << 'EOF'
[Master template with:]
TASK: Implement Task W3-2 from spec/14_BUILD_PLAN.md.
Read spec 08 OAuth section, 18A (Node bundling), 19D (token expiry),
20D (universal binary), 20F (pipe deadlock), 20H (sidecar orphan), 21H (orphan prevention).
Implement AnthropicOAuthProvider.swift, SidecarManager.swift,
sidecar.js, package.json, Xcode build phase for Node binary.
BRANCH: feature/anthropic-oauth
EOF
claude "$(cat tasks/W3-2.md)" > logs/W3-2.log 2>&1 &

# Terminal 2
cat > tasks/W3-3.md << 'EOF'
[Master template with:]
TASK: Implement Task W3-3 from spec/14_BUILD_PLAN.md.
Read spec section 11 settings UI from 09_10_11 file.
Read spec 19J (custom base URL), 20Q (cmd comma shortcut), 20T (dark mode).
Implement all 4 settings tabs (General, Providers, Prompts, Logs).
Wire SMAppService for launch at login in GeneralSettingsView.
BRANCH: feature/settings-ui
EOF
claude "$(cat tasks/W3-3.md)" > logs/W3-3.log 2>&1 &
```

---

### WEEK 4 — Parallel where possible

```bash
# These can all run simultaneously after W3-1 merges

# Terminal 1
claude "$(cat tasks/W4-1.md)" > logs/W4-1.log 2>&1 &   # Result actions
# Terminal 2
claude "$(cat tasks/W4-2.md)" > logs/W4-2.log 2>&1 &   # Continue chat
# Terminal 3
claude "$(cat tasks/W4-5.md)" > logs/W4-5.log 2>&1 &   # Prompt editing (21A)
# Terminal 4
claude "$(cat tasks/W4-6.md)" > logs/W4-6.log 2>&1 &   # No-provider + resilience

# W4-3 and W4-4 depend on the above — run after
```

---

### WEEK 5 — Infrastructure and polish

```bash
# W5-1 (CI) can run immediately — no code dependencies
claude "$(cat tasks/W5-1.md)" > logs/W5-1.log 2>&1 &

# These need Week 4 merged first, then can run in parallel:
# W5-2 (onboarding), W5-3 (crash reporter), W5-7 (strings/logger),
# W5-8 (performance tests), W5-9 (SwiftData history)

# W5-5 (Sparkle) and W5-6 (sleep/wake) are independent
```

---

## PHASE 7 — The Review → Fix → Merge Loop (Exact Steps)

Do this for every branch, every time.

### Step 1: Feature agent finishes

You see `FEATURE_AGENT_DONE` in the output. Note the branch name.

### Step 2: Run Review Agent

```bash
cat > review_task.md << 'EOF'
[Review Agent prompt from PHASE 3, with branch name filled in]
EOF

claude "$(cat review_task.md)" > review_output.txt 2>&1
cat review_output.txt | tail -30
```

### Step 3a: If PASS

```bash
# Run merge agent
cat > merge_task.md << 'EOF'
[Merge Agent prompt from PHASE 5, with branch name and commit message]
EOF

claude "$(cat merge_task.md)"
```

Done. Move to next task.

### Step 3b: If FAIL

```bash
# Run fix agent — paste the FAIL output
cat > fix_task.md << 'EOF'
[Fix Agent prompt from PHASE 4]
[Paste the full content of review_output.txt here]
EOF

claude "$(cat fix_task.md)"

# Then go back to Step 2 (Review Agent again)
# Repeat until PASS, max 5 iterations
# If still failing after 5: STOP and read the issues manually
```

---

## PHASE 8 — Handling Merge Conflicts Between Parallel Agents

When two Week 2 agents both modified `AppState.swift` or `AppError.swift`:

```bash
# After merging branch A, when merging branch B you get a conflict

git checkout develop
git pull origin develop
git merge --squash feature/branch-b
# CONFLICT in AppState.swift

# Open the conflict in your editor
# Rule: KEEP ALL additions from both sides
# The develop version already has branch-A's additions
# Add branch-B's new properties AFTER them, in the correct MARK section

git add AppState.swift
git commit -m "feat(scope): branch-b description"
git push origin develop
```

**Golden rule:** Never delete the other agent's code when resolving conflicts.
Both sides are adding new things — just combine them.

---

## PHASE 9 — Checking Progress at Any Point

```bash
# See all branches
git branch -a

# See what's merged into develop
git log --oneline develop | head -20

# See what's still open (not merged)
git branch -r | grep -v develop | grep -v main

# Check CI status
gh run list --limit 10

# Run all tests locally
xcodebuild test \
  -scheme AITextTool \
  -destination 'platform=macOS' \
  | tail -20
```

---

## PHASE 10 — First Smoke Test (After W3-1 Merges)

At this point you have the panel working. Do a manual test:

1. Build and run in Xcode (⌘R)
2. Grant Accessibility permission when prompted
3. Grant Input Monitoring permission when prompted
4. Open TextEdit, type something, select it
5. Press ⌥Space
6. Panel should appear within 200ms
7. Press Escape — panel dismisses

If this works, the core flow is solid. Continue with Week 4.

---

## PHASE 11 — Quick Reference Card

```
AGENT TYPE      WHEN TO USE                    KEY OUTPUT
─────────────────────────────────────────────────────────
Feature Agent   Implementing a task            FEATURE_AGENT_DONE
Review Agent    After every feature agent      REVIEW_AGENT_RESULT: PASS/FAIL
Fix Agent       After FAIL (max 5x)            FIX_AGENT_DONE
Merge Agent     After PASS                     MERGE_AGENT_DONE

BRANCH RULES
─────────────────────────────────────────────────────────
Always branch from:    develop
Never commit to:       main, develop directly
Name format:           feature/*, fix/*, chore/*, test/*
After merge:           branch deleted automatically by merge agent

MERGE ORDER (Week 2 — must be sequential to avoid conflicts)
─────────────────────────────────────────────────────────
W2-1 hotkey → W2-2 capture → W2-3 replace → W2-4 ai → W2-5 prompts → W2-6 settings

PARALLEL-SAFE (can run simultaneously, no shared file writes)
─────────────────────────────────────────────────────────
W2-1, W2-2, W2-3, W2-4 (all independent modules)
W3-2, W3-3 (after W3-1 merges)
W4-1, W4-2, W4-5, W4-6 (after W3-1 merges)
W5-1, W5-2, W5-3, W5-5, W5-6, W5-7, W5-8 (after Week 4 merges)

ESCALATE TO HUMAN IF
─────────────────────────────────────────────────────────
Fix agent hits iteration 5 with no progress
Review agent finds a spec contradiction
Tests pass but app crashes on first run
Merge conflict touches logic (not just additions)
```

---

## PHASE 12 — Common Pitfalls and How to Avoid Them

**Agent writes outside its scope**
→ Review Agent catches this via checklist item C5
→ Fix Agent removes the extra files

**Agent forgets to read all spec files**
→ The prompt explicitly says "do not write code until all files are read"
→ If output looks wrong, check if the agent referenced spec file numbers

**Tests fail only on CI, pass locally**
→ Usually a hardcoded path or `UserDefaults.standard` leak between tests
→ Fix Agent reads 12_TESTING.md isolation rules

**Parallel agents conflict on `AppState.swift`**
→ Follow Phase 8 — keep both sides' additions
→ If complex: run Integration Agent from spec 20B

**Sidecar not found on first run**
→ The Xcode build phase for downloading Node hasn't run yet
→ Clean build (⌘⇧K) then rebuild

**`⌥Space` doesn't fire**
→ Check System Settings → Privacy → Input Monitoring → AITextTool is toggled ON
→ If not listed: delete and reinstall the app

**Panel doesn't receive keyboard input**
→ `canBecomeKey` must return `true` on FloatingPanel — check spec 21D
→ `makeKeyAndOrderFront(nil)` must be called AFTER text is captured

---

## Estimated Total Time

| Phase | Time | Who |
|-------|------|-----|
| Phase 0 setup | 30 min | You |
| Week 1 (W1-1, W1-2) | 2–3 hours | Agents |
| Week 2 (parallel) | 3–4 hours | Agents |
| Week 2 reviews + merges | 1 hour | You + agents |
| Week 3 | 3–4 hours | Agents |
| Week 4 | 3–4 hours | Agents |
| Week 5 | 2–3 hours | Agents |
| Final testing | 1 hour | You |
| **Total** | **~2 days** | |

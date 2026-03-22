# 03 — Agent Protocol

## Roles

There are three agent types. Each has one job and should not exceed it.

---

### Agent Type 1: Feature Agent

**Trigger:** Human assigns a feature from the build plan.

**Reads:** All spec files (00_INDEX through 20_REMAINING_GAPS) in order before writing any code.

**Responsibilities:**
- Implements exactly what the spec says for the assigned feature
- Writes all tests required by `12_TESTING.md` for that feature
- Follows architecture in `04_ARCHITECTURE.md` exactly
- Does NOT refactor unrelated code
- Does NOT add features not in the spec
- Commits with conventional commit format
- Pushes branch and outputs the branch name for the Review Agent

**Output format (must be last thing printed):**
```
FEATURE_AGENT_DONE
branch: feature/<name>
commits: <N>
tests_added: <N>
files_changed: <list>
```

---

### Agent Type 2: Review Agent

**Trigger:** Feature Agent outputs `FEATURE_AGENT_DONE`

**Reads:** `13_REVIEW_CHECKLIST.md`, `12_TESTING.md`, `04_ARCHITECTURE.md`

**Responsibilities:**
- Run: `xcodebuild test -scheme AITextTool -destination 'platform=macOS'`
- Run: `swiftlint lint --strict`
- Diff: `git diff develop...feature/<name>`
- Check every item in `13_REVIEW_CHECKLIST.md`
- Does NOT fix code — only reports

**Output format (must be last thing printed):**

If passing:
```
REVIEW_AGENT_RESULT: PASS
branch: feature/<name>
```

If failing:
```
REVIEW_AGENT_RESULT: FAIL
branch: feature/<name>
issues:
  - [FILE:LINE] <description of issue>
  - [FILE:LINE] <description of issue>
  ...
test_failures:
  - <test name>: <failure message>
  ...
lint_warnings:
  - <file>:<line>: <rule>: <message>
  ...
```

---

### Agent Type 3: Fix Agent

**Trigger:** Review Agent outputs `REVIEW_AGENT_RESULT: FAIL`

**Reads:** The `issues`, `test_failures`, `lint_warnings` from the Review Agent output.
Also reads the spec files relevant to the flagged issues.

**Responsibilities:**
- Fix ONLY the flagged items. Nothing else.
- Each fix is a separate commit with message: `fix(<scope>): <what was fixed>`
- After all fixes are committed and pushed, outputs:

```
FIX_AGENT_DONE
branch: feature/<name>
fixes_applied: <N>
```

This triggers a new Review Agent run. The loop continues until `REVIEW_AGENT_RESULT: PASS`.

---

### Agent Type 4: Merge Agent

**Trigger:** Review Agent outputs `REVIEW_AGENT_RESULT: PASS`

**Responsibilities:**
```bash
# 1. Ensure develop is up to date
git checkout develop && git pull origin develop

# 2. Squash merge the feature branch
git merge --squash feature/<name>

# 3. Commit with conventional format
git commit -m "feat(<scope>): <description from PR title>"

# 4. Push
git push origin develop

# 5. Delete feature branch
git push origin --delete feature/<name>
git branch -d feature/<name>

# 6. Output
echo "MERGE_AGENT_DONE: feature/<name> merged into develop"
```

---

## Loop Diagram

```
Human assigns feature
        │
        ▼
  Feature Agent ──────────────────────────────────────────┐
        │                                                  │
        │ FEATURE_AGENT_DONE                               │
        ▼                                                  │
  Review Agent                                             │
        │                                                  │
   PASS │    FAIL                                          │
        │     │                                            │
        │     ▼                                            │
        │  Fix Agent ─── FIX_AGENT_DONE ──► Review Agent  │
        │                                       │          │
        │                                  PASS │  FAIL    │
        │                                       │    │     │
        │ ◄─────────────────────────────────────┘    │     │
        │                                             │     │
        │                              (loop back to Fix)   │
        ▼                                                   │
  Merge Agent                                              │
        │                                                  │
        │ MERGE_AGENT_DONE                                 │
        ▼                                                  │
Human assigns next feature ────────────────────────────────┘
```

---

## Context Each Agent Must Have

Every agent session must start with:

```
You are working on AITextTool, a macOS menu bar app. 
Read all files in the /spec folder before doing anything else.
The current task is: [TASK DESCRIPTION]
The current branch is: [BRANCH NAME or "none — create new"]
```

Never assume context from a previous agent session. Each agent starts fresh.

---

## Parallel Agent Strategy (Advanced)

Once the core architecture is in place (Week 1-2), independent modules
can be developed in parallel by different agents simultaneously:

```
develop
├─ feature/ai-providers      ← Agent A (no UI dependency)
├─ feature/prompt-store      ← Agent B (no UI dependency)  
└─ feature/text-capture      ← Agent C (no UI dependency)
```

Modules with UI dependencies must wait for FloatingPanel to be merged first.

Merge order:
1. `feature/hotkey-manager` (no deps)
2. `feature/text-capture` (no deps)
3. `feature/ai-providers` (no deps)
4. `feature/prompt-store` (no deps)
5. `feature/floating-panel` (depends on 1-4 being merged)
6. `feature/settings` (depends on 3, 4)
7. `feature/result-actions` (depends on 2, 5)
8. `feature/diff-view` (depends on 5)
9. `feature/continue-chat` (depends on 5, 3)

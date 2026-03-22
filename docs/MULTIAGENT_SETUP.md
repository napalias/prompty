# How to Run Multiple Agents in Claude Code
## The Native Way — Subagents + Agent Teams

---

## First: Understand the Two Mechanisms

Subagents work within a single session. Agent Teams coordinate across separate sessions.

This matters a lot for your project:

| | Subagents | Agent Teams |
|--|-----------|-------------|
| How they run | Inside your current `claude` session | Each in their own session |
| Communication | Report back to parent only | Can talk to each other directly |
| Context | Each gets a fresh 200K window | Each gets a fresh 200K window |
| When to use | Sequential or light parallel tasks | Heavy parallel work, teammates need to coordinate |
| Cost | ~3-4x a single session | ~4-7x a single session |
| Setup | Create `.claude/agents/` files | Same + enable experimental flag |

**For AITextTool:** Use **subagents** for Week 1-2 (sequential or light parallel), and **Agent Teams** for Week 2-4 where multiple independent modules need to be built simultaneously.

---

## Step 1 — Create the Agent Definition Files

Inside your repo, create this folder structure:

```
AITextTool/
└── .claude/
    ├── agents/
    │   ├── feature-agent.md
    │   ├── review-agent.md
    │   ├── fix-agent.md
    │   └── merge-agent.md
    └── CLAUDE.md              ← orchestration rules
```

---

### `.claude/agents/feature-agent.md`

```markdown
---
name: feature-agent
description: Implements a single feature task from the build plan. Use when asked to implement any task from spec/14_BUILD_PLAN.md or later spec files. Triggered by phrases like "implement task W2-1", "build the hotkey module", "create feature branch for X".
tools: Read, Write, Edit, Bash, Glob, Grep
model: opus
---

You are a Feature Agent for AITextTool, a macOS menu bar app.

## Your job
Implement exactly one feature task from the build plan. Nothing more.

## Before writing any code
Read every spec file in order:
spec/00_INDEX.md → spec/01_PROJECT_OVERVIEW.md → spec/02_GITFLOW.md →
spec/03_AGENT_PROTOCOL.md → spec/04_ARCHITECTURE.md →
spec/05_06_07_MODULES_HOTKEY_CAPTURE_REPLACE.md →
spec/08_MODULE_AI_PROVIDERS.md → spec/09_10_11_MODULES_PROMPTS_UI_SETTINGS.md →
spec/12_TESTING.md → spec/13_REVIEW_CHECKLIST.md → spec/14_BUILD_PLAN.md →
spec/15_CI_CD.md → spec/16_EDGE_CASES.md → spec/17_UPDATES_CRASHREPORTING_HISTORY.md →
spec/18_CRITICAL_GAPS.md → spec/19_FINAL_GAPS.md → spec/20_REMAINING_GAPS.md →
spec/21_PROMPT_EDITING_AND_AUDIT_FIXES.md

Do NOT write any code until you have finished reading all spec files.

## Git workflow
1. `git checkout develop && git pull origin develop`
2. `git checkout -b feature/<branch-name>`
3. Implement the task
4. Write all required tests
5. `swiftlint lint --strict` — fix all warnings before committing
6. `xcodebuild test -scheme AITextTool -destination 'platform=macOS'` — all tests must pass
7. `git add -A && git commit -m "feat(scope): description"`
8. `git push origin feature/<branch-name>`

## Rules
- Only implement what the spec says for this task
- Every new public method must have at least one test
- No force unwraps, no print(), no hardcoded strings
- Follow 04_ARCHITECTURE.md folder structure exactly

## Output when done
Print exactly this (last thing you print):
FEATURE_AGENT_DONE
branch: feature/<name>
commits: <N>
tests_added: <N>
files_changed: <comma-separated list>
```

---

### `.claude/agents/review-agent.md`

```markdown
---
name: review-agent
description: Reviews a feature branch against develop. Use after a feature agent finishes. Triggered by "review branch X", "check feature/X", "FEATURE_AGENT_DONE received". Read-only — never modifies code.
tools: Read, Bash, Glob, Grep
model: sonnet
---

You are a Review Agent for AITextTool. You review code but NEVER modify it.

## Before reviewing
Read: spec/13_REVIEW_CHECKLIST.md, spec/12_TESTING.md, spec/04_ARCHITECTURE.md

## Review steps — run in this exact order

1. `git fetch origin`
2. `git checkout <branch-name>`
3. `git merge-base --is-ancestor origin/develop HEAD` — if fails, FAIL immediately (branch is stale)
4. `xcodebuild test -scheme AITextTool -destination 'platform=macOS' -enableCodeCoverage YES -resultBundlePath TestResults.xcresult 2>&1 | tail -30`
5. `swiftlint lint --strict 2>&1`
6. `git diff origin/develop...<branch-name> 2>&1`
7. Check every item in spec/13_REVIEW_CHECKLIST.md against what you see

## Output format — PASS
Print exactly:
REVIEW_AGENT_RESULT: PASS
branch: <branch-name>

## Output format — FAIL
Print exactly:
REVIEW_AGENT_RESULT: FAIL
branch: <branch-name>
issues:
  - [FILE:LINE] description of issue
test_failures:
  - TestName: failure message
lint_warnings:
  - file:line: rule: message
```

---

### `.claude/agents/fix-agent.md`

```markdown
---
name: fix-agent
description: Fixes issues found by the review agent. Use after REVIEW_AGENT_RESULT: FAIL. Triggered by "fix the review failures on branch X" or when given a FAIL output. Only fixes what was flagged — nothing else.
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
---

You are a Fix Agent for AITextTool. Fix only what the review agent flagged.

## Rules
- Fix ONLY the listed issues from the review output
- Do NOT refactor anything else
- Do NOT add features
- Each fix is a separate commit: `fix(scope): what was fixed`
- After all fixes, push the branch

## Iteration limit
Track your iteration number. If you are on iteration 5 and issues remain, output:
LOOP_LIMIT_REACHED
branch: <name>
unresolved_issues: <list>
action_required: Human must inspect — spec may be contradictory

## Output when done
Print exactly:
FIX_AGENT_DONE
branch: <branch-name>
fixes_applied: <N>
iteration: <N>
```

---

### `.claude/agents/merge-agent.md`

```markdown
---
name: merge-agent
description: Merges a passing branch into develop. Use after REVIEW_AGENT_RESULT: PASS. Triggered by "merge branch X" or "PASS received, merge it".
tools: Bash
model: haiku
---

You are a Merge Agent for AITextTool. Squash-merge passing branches into develop.

## Steps
```bash
git checkout develop
git pull origin develop
git merge --squash <branch-name>
git commit -m "<conventional commit message summarising the PR>"
git push origin develop
git push origin --delete <branch-name>
git branch -d <branch-name>
```

## Output
Print exactly:
MERGE_AGENT_DONE: <branch-name> merged into develop
```

---

## Step 2 — Create `CLAUDE.md` (Orchestration Rules)

This file is read by Claude Code at the start of every session. It teaches the orchestrator when to use each agent and how to handle dependencies.

```markdown
# AITextTool — Project Orchestration Rules

## Project
macOS menu bar app. Swift 5.10, Xcode 16, macOS 15 minimum.
All spec files are in ./spec/ — agents must read them before doing anything.

## Agent Routing Rules

### Use feature-agent when:
- Asked to implement any task from the build plan
- Task names like W1-1, W2-3, W4-5 etc
- "Build", "implement", "create" + a module name

### Use review-agent when:
- FEATURE_AGENT_DONE output appears
- Asked to "review branch X"
- After any code is written

### Use fix-agent when:
- REVIEW_AGENT_RESULT: FAIL appears
- Asked to "fix review failures"

### Use merge-agent when:
- REVIEW_AGENT_RESULT: PASS appears
- Asked to "merge branch X"

## Parallel Dispatch Rules
Run these tasks in PARALLEL (independent modules, no shared file writes):
- W2-1 (hotkey) + W2-2 (text capture) + W2-3 (text replace) + W2-4 (AI providers)
- W3-2 (OAuth sidecar) + W3-3 (settings UI) — only after W3-1 is merged
- W4-1 + W4-2 + W4-5 + W4-6 — only after W3-1 is merged
- W5-2 + W5-3 + W5-7 + W5-8 — only after Week 4 is merged

## Sequential Dispatch Rules
Run these in ORDER (shared files — merge each before starting next):
- W1-1 → W1-2
- Merge W2-1 before W2-2, W2-2 before W2-3, etc (prevent AppState conflicts)
- W3-1 must be fully merged before any W3-2/W3-3/W4-x starts

## Conflict Resolution
If two parallel agents both modify AppState.swift or AppError.swift:
- The second agent to finish must rebase onto develop after the first merges
- Keep ALL additions from both sides — never delete the other agent's code
- Run `git rebase origin/develop` before the review agent runs

## Sub-Agent Routing
Parallel = tasks have no shared files and can finish independently
Sequential = B depends on output from A, or they both write to same files

## Loop Limit
Fix agent max 5 iterations. On LOOP_LIMIT_REACHED, stop and tell the human.
```

---

## Step 3 — Enable Agent Teams (for true parallel execution)

Agent Teams is experimental and disabled by default. Enable it:

```bash
# Option A: environment variable (per session)
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
claude

# Option B: permanently in settings.json (~/.claude/settings.json)
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Use Shift+Down to cycle through teammates in your terminal, or use split panes with tmux/iTerm2 so you see all agents' output simultaneously.

---

## Step 4 — How to Actually Talk to Claude Code

### For sequential tasks (Week 1) — one at a time

```
Implement task W1-1 from the build plan
```

Claude delegates to `feature-agent` automatically. When it prints `FEATURE_AGENT_DONE`, say:

```
Review the branch it just created
```

Claude delegates to `review-agent`. If PASS:

```
Merge it
```

If FAIL:

```
Fix the review failures on that branch
```

---

### For parallel tasks (Week 2) — all at once

Claude Code uses sub-agents conservatively by default. To maximize parallelization, be explicit in your prompts.

```
Implement tasks W2-1, W2-2, W2-3, and W2-4 in parallel using 4 separate 
feature agents running simultaneously. Each agent works on its own branch.
Do not start W2-2 until W2-1's branch is named — they can otherwise run 
truly in parallel since they touch different files.
```

The lead agent will decompose this, assign roles, and spawn the subagents. You'll see output indicating which agents are active and what each is working on.

When all 4 print `FEATURE_AGENT_DONE`:

```
Review all 4 branches in parallel using 4 separate review agents
```

When all 4 pass:

```
Merge the 4 branches in this order: W2-1 first, then W2-2, then W2-3, then W2-4.
Merge each one before starting the next to prevent conflicts on shared files.
```

---

### For the Agent Teams approach (Week 3+) — teammates that coordinate

```
Using agent teams, implement W3-2 (OAuth sidecar) and W3-3 (settings UI) in 
parallel. These are independent — assign one teammate to each branch. 
Both should read the spec first, then work simultaneously.
```

In practice, teammates typically spawn within 20-30 seconds and begin producing results within the first minute.

---

## Step 5 — The Exact Prompts Week by Week

Copy-paste these directly into Claude Code.

### Week 1 (run these one at a time)

```
Implement task W1-1 from spec/14_BUILD_PLAN.md using the feature-agent
```
→ Wait for FEATURE_AGENT_DONE → Review → Merge

```
Implement task W1-2 from spec/14_BUILD_PLAN.md using the feature-agent
```
→ Wait for FEATURE_AGENT_DONE → Review → Merge

---

### Week 2 (all 4 in parallel, merge sequentially)

```
Use 4 parallel feature agents to implement tasks W2-1, W2-2, W2-3, and W2-4 
simultaneously. Each agent creates its own branch and works independently.
Tasks: 
- W2-1 on branch feature/hotkey-manager
- W2-2 on branch feature/text-capture  
- W2-3 on branch feature/text-replace
- W2-4 on branch feature/ai-providers
Start all 4 at the same time.
```

→ When all 4 done:

```
Review all 4 branches using parallel review agents simultaneously
```

→ When all 4 pass:

```
Merge these branches one at a time in this exact order, waiting for each 
merge to complete before starting the next:
1. feature/hotkey-manager
2. feature/text-capture
3. feature/text-replace
4. feature/ai-providers
```

→ Then W2-5 and W2-6 sequentially:

```
Implement W2-5 on branch feature/prompt-store, then after it merges, 
implement W2-6 on branch feature/settings-core
```

---

### Week 3 (W3-1 first, then W3-2 and W3-3 in parallel)

```
Implement task W3-1 (floating panel) using the feature-agent
```
→ Review → Merge (this one takes time — it's the biggest UI task)

```
Use agent teams to implement W3-2 and W3-3 in parallel:
- Teammate 1: implement W3-2 (Claude OAuth sidecar) on branch feature/anthropic-oauth
- Teammate 2: implement W3-3 (settings UI) on branch feature/settings-ui
Both can work simultaneously — they touch different files
```

---

### Week 4 (4 tasks in parallel)

```
Use 4 parallel feature agents to implement these simultaneously:
- W4-1 on feature/result-actions
- W4-2 on feature/continue-chat
- W4-5 on feature/prompt-editor
- W4-6 on feature/empty-state-resilience

Then after all 4 are reviewed and passing, implement W4-3 and W4-4.
```

---

### Week 5 (parallel infrastructure)

```
Use parallel feature agents for these independent infrastructure tasks:
- W5-1 on chore/ci-setup
- W5-2 on feature/onboarding
- W5-3 on feature/crash-reporter
- W5-5 on feature/sparkle-updater
- W5-6 on fix/runtime-stability
- W5-7 on chore/shared-utilities
- W5-8 on test/performance-baseline
- W5-9 on feature/swiftdata-history (replaces W5-4)

These are all independent — run as many in parallel as possible.
```

---

## Step 6 — Watching What's Happening

```bash
# See all active agents and their status
# In Claude Code session, press Shift+Down to cycle between agents

# Watch git branches being created
watch -n 2 'git branch -r | grep -v main'

# See test results as they come in
tail -f /tmp/claude-agent-*.log 2>/dev/null

# Check CI status for all branches
gh run list --limit 20
```

---

## Step 7 — When Things Go Wrong

### An agent is stuck or looping

In Claude Code, type:
```
The fix agent on branch feature/X has hit iteration 3 with no progress. 
Review the unresolved issues and tell me what's wrong with the spec.
```

### Two agents created a merge conflict

```
There's a merge conflict on AppState.swift between feature/text-capture 
and feature/ai-providers. Resolve it by keeping all additions from both 
branches — do not delete either side's new properties.
```

### An agent went outside its scope

```
The review agent flagged that feature/text-capture modified AppDelegate.swift 
which was outside its task scope. Revert those changes on the branch.
```

### CI is failing but tests pass locally

```
CI is failing on branch feature/X but tests pass locally. 
Check for UserDefaults.standard usage outside SettingsRepository, 
and any hardcoded file paths in tests.
```

---

## Summary: The Exact Words That Trigger Multiple Agents

These phrases cause Claude Code to spawn parallel subagents:

| What you want | What to say |
|--------------|-------------|
| 4 parallel feature agents | `"Use 4 parallel feature agents to implement..."` |
| Agent teams (coordinating) | `"Use agent teams to implement X and Y simultaneously"` |
| Sequential with dependencies | `"Implement X, then after it merges, implement Y"` |
| Parallel reviews | `"Review all N branches using parallel review agents"` |
| Sequential merges | `"Merge in this exact order: 1, 2, 3, 4"` |

Be specific about the number of sub-agents. "Use 5 parallel tasks" is clearer than "parallelize this work." Define what each sub-agent should focus on.

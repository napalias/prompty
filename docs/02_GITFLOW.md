# 02 — GitFlow Strategy

## Branch Model

```
main          ← production-ready, tagged releases only
  └─ develop  ← integration branch, always green (tests pass)
       ├─ feature/hotkey-manager
       ├─ feature/text-capture
       ├─ feature/ai-providers
       ├─ feature/prompt-store
       ├─ feature/floating-panel
       ├─ feature/settings
       ├─ fix/ax-fallback-crash
       └─ chore/add-swiftlint
```

## Branch Naming Convention

```
feature/<short-kebab-description>   # new capability
fix/<short-kebab-description>       # bug fix
chore/<short-kebab-description>     # tooling, docs, refactor
test/<short-kebab-description>      # tests only (no production code changes)
```

Rules:
- Branch names are lowercase kebab-case only
- Max 50 characters total
- Always branch OFF `develop`, never off `main`
- Never commit directly to `main` or `develop`

---

## Commit Convention (Conventional Commits)

Format:
```
<type>(<scope>): <short description>

[optional body]

[optional footer: refs #issue, BREAKING CHANGE: ...]
```

Types:
| Type | When to use |
|------|------------|
| `feat` | New feature or behaviour |
| `fix` | Bug fix |
| `test` | Adding or fixing tests only |
| `refactor` | Code change that is neither fix nor feat |
| `chore` | Build, tooling, dependency updates |
| `docs` | Documentation only |
| `style` | Formatting, whitespace (no logic change) |
| `perf` | Performance improvement |

Scope = module name: `hotkey`, `text-capture`, `ai`, `prompts`, `ui`, `settings`, `sidecar`

Examples:
```
feat(text-capture): add clipboard fallback for Electron apps
fix(ai): handle Ollama connection refused error gracefully
test(hotkey): add unit tests for modifier key parsing
chore: add SwiftLint configuration
```

Rules:
- Subject line ≤ 72 characters
- Present tense ("add" not "added")
- No period at end of subject
- Body explains WHY, not what (code shows what)

---

## PR Rules

### Title
Must follow commit convention: `type(scope): description`

### Required Sections in PR Description
```markdown
## What
<!-- One paragraph: what this PR adds/changes/fixes -->

## Why
<!-- Context: why was this needed -->

## How
<!-- Key technical decisions made -->

## Test Coverage
<!-- What tests were added. Paste test names. -->

## Checklist
- [ ] All tests pass locally
- [ ] SwiftLint passes with zero warnings
- [ ] No TODO/FIXME left in code (or explicitly tracked in issues)
- [ ] Review checklist passed (see 13_REVIEW_CHECKLIST.md)
```

### Merge Rules
1. Target branch is always `develop` (never `main`)
2. Squash merge — one commit per PR on develop
3. Delete source branch after merge
4. PR can only merge if:
   - Review agent output is `PASS`
   - All XCTest targets pass
   - SwiftLint reports 0 warnings, 0 errors

### Merge to Main
Only done manually by the human owner when creating a release.
Tag format: `v0.1.0`, `v0.2.0` (semantic versioning)
Release notes auto-generated from squash commit messages since last tag.

---

## Agent Workflow for Each Feature

```
1. Human: "Implement [FEATURE] per spec"
         │
         ▼
2. Feature Agent:
   - git checkout develop && git pull
   - git checkout -b feature/<name>
   - implement per spec
   - write tests per 12_TESTING.md
   - git add -A && git commit (conventional commit)
   - git push origin feature/<name>
         │
         ▼
3. Review Agent:
   - git fetch && git diff develop...feature/<name>
   - run tests: xcodebuild test
   - run lint: swiftlint
   - check each item in 13_REVIEW_CHECKLIST.md
   - output: PASS or FAIL with specific line references
         │
    ┌────┴────┐
  FAIL       PASS
    │          │
    ▼          ▼
4. Fix Agent  5. Merge Agent:
   - read        - gh pr create (or git merge --squash)
     FAIL         - git push origin develop
     reasons      - git branch -d feature/<name>
   - fix only
     flagged
     items
   - commit
   - go back
     to step 3
```


---

## Parallel Agent Merge Conflict Protocol

When two agents work on different branches simultaneously, they may both modify
shared files (`AppState.swift`, `AppError.swift`, folder structure).

### Rules for parallel agents

1. **Shared files are owned by one agent at a time.** If Task A and Task B both
   need to add to `AppError.swift`, the second agent to finish must rebase onto
   `develop` after the first merges and resolve conflicts manually.

2. **Rebase before opening for review.** Before the Review Agent runs, the Feature
   Agent must always:
   ```bash
   git fetch origin
   git rebase origin/develop
   # Resolve any conflicts, then:
   git push --force-with-lease origin feature/<n>
   ```

3. **Conflict resolution rule:** When rebasing, the incoming `develop` changes
   always win for structural files (`AppState.swift`, `AppError.swift`,
   `04_ARCHITECTURE.md`). The feature agent adds its additions *after* the
   existing develop content, never replaces it.

4. **The Feature Agent detects staleness.** At the start of implementation,
   run `git log --oneline origin/develop..HEAD`. If this shows 0 commits,
   the branch is behind develop — pull and rebase before writing any code.

5. **Review Agent checks for staleness.** Item **E6** in the review checklist:
   `git merge-base --is-ancestor origin/develop HEAD` — if this fails, the
   branch must be rebased before review continues.

---

## Initial Repository Setup Commands

```bash
# Run once by human to set up repo
git init AITextTool
cd AITextTool
git checkout -b develop
git commit --allow-empty -m "chore: initial repository setup"
git push -u origin develop

# Protect branches (GitHub CLI)
gh repo create AITextTool --private
gh api repos/:owner/AITextTool/branches/develop/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["test"]}' \
  --field enforce_admins=false \
  --field required_pull_request_reviews='{"required_approving_review_count":0}'
```

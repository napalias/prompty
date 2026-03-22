---
description: Spec-aware Feature Agent - reads all docs, creates branch off develop, implements per spec with tests
---

# Feature Agent

## Input

Feature description: $ARGUMENTS

## Instructions

You are the **Feature Agent** for AITextTool. Follow this protocol exactly.

### Phase 1: Read the Spec

1. Read ALL spec files in `docs/` in order, starting with `docs/00_INDEX.md` through `docs/21_PROMPT_EDITING_AND_AUDIT_FIXES.md`.
2. Do NOT write any code until you have read every spec file.

### Phase 2: Branch Setup

3. Ensure `develop` branch exists. If not, use `main`.
4. Checkout the base branch and pull latest:
   ```
   git checkout develop && git pull origin develop
   ```
5. Create a feature branch with a short kebab-case name derived from `$ARGUMENTS`:
   ```
   git checkout -b feature/<generated-name>
   ```
6. Check for staleness: `git log --oneline origin/develop..HEAD` — if behind, rebase first.

### Phase 3: Implementation

7. Implement EXACTLY what the spec says for the assigned feature.
8. Follow the architecture in `docs/04_ARCHITECTURE.md` — DI via initializer, protocol-first, value types.
9. Follow the folder structure defined in the spec.
10. Use `@MainActor` on all `AppState` mutations and UI-touching code.
11. Use `AsyncThrowingStream` for streaming.
12. All user-facing strings go in `Strings.swift`.
13. No hardcoded strings in views.

### Phase 4: Testing

14. Write all tests required by `docs/12_TESTING.md` for this feature.
15. Create mock implementations for all protocol dependencies.
16. Tests must be in `AITextToolTests/<module>/` matching the spec structure.

### Phase 5: Commit & Report

17. Use conventional commit format: `feat(<scope>): <description>`
18. Scopes: `hotkey`, `text-capture`, `ai`, `prompts`, `ui`, `settings`, `sidecar`
19. Stage only relevant files (no `git add -A`).
20. Push the branch: `git push -u origin feature/<name>`
21. Output the completion report:

```
FEATURE_AGENT_DONE
branch: feature/<name>
commits: <N>
tests_added: <N>
files_changed: <list>
```

### Rules
- Do NOT refactor unrelated code
- Do NOT add features not in the spec
- Do NOT modify `AppError` cases without spec approval
- Keep `SWIFT_STRICT_CONCURRENCY = complete` — zero data-race warnings

---
description: Build & Test - runs xcodebuild build + test + swiftlint and reports results
---

# Build & Test

## Instructions

Run the full build pipeline for AITextTool and report results.

### Step 1: Build

```
xcodebuild build -scheme AITextTool -destination 'platform=macOS' 2>&1
```

Report: PASS or FAIL with error details.

### Step 2: Test

```
xcodebuild test -scheme AITextTool -destination 'platform=macOS' 2>&1
```

Report: PASS or FAIL with failing test names and messages.

### Step 3: Lint

```
swiftlint lint --strict 2>&1
```

Report: PASS or FAIL with warning/error counts and details.

### Summary

Output a summary table:

```
BUILD RESULTS
=============
Build:    PASS/FAIL
Tests:    PASS/FAIL (X passed, Y failed)
Lint:     PASS/FAIL (X warnings, Y errors)
Overall:  PASS/FAIL
```

If any step fails, show the relevant error output for quick diagnosis.

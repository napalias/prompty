# 15 — CI/CD Pipeline (GitHub Actions)

## Philosophy
Every push to any branch runs the full quality gate automatically.
Agents must never assume their local run is sufficient — CI is the source of truth.
A PR cannot be considered passing unless the CI badge is green.

---

## Workflow Files

### `.github/workflows/ci.yml` — Runs on every push and PR

```yaml
name: CI

on:
  push:
    branches: ['**']        # every branch
  pull_request:
    branches: [develop, main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true  # cancel stale runs when new commit pushed

jobs:
  test:
    name: Test & Lint
    runs-on: macos-15        # Apple Silicon runner (M2), Xcode 16 pre-installed
    timeout-minutes: 20

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.app

      - name: Cache SPM packages
        uses: actions/cache@v4
        with:
          path: |
            ~/Library/Developer/Xcode/DerivedData
            .build
          key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}
          restore-keys: ${{ runner.os }}-spm-

      - name: Resolve packages
        run: xcodebuild -resolvePackageDependencies -scheme AITextTool

      - name: Lint
        run: |
          brew install swiftlint
          swiftlint lint --strict --reporter github-actions-logging

      - name: Build
        run: |
          xcodebuild build \
            -scheme AITextTool \
            -destination 'platform=macOS' \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO \
            | xcpretty

      - name: Test
        run: |
          xcodebuild test \
            -scheme AITextTool \
            -destination 'platform=macOS' \
            -enableCodeCoverage YES \
            -resultBundlePath TestResults.xcresult \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO \
            | xcpretty

      - name: Check coverage
        run: |
          xcrun xccov view --report --json TestResults.xcresult \
            > coverage.json
          # Fail if any service file is below 80%
          python3 .github/scripts/check_coverage.py coverage.json 80

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: TestResults-${{ github.sha }}
          path: TestResults.xcresult
          retention-days: 7
```

---

### `.github/scripts/check_coverage.py`

```python
#!/usr/bin/env python3
"""
Reads xccov JSON output and fails if any service/repository/utility
file has line coverage below the threshold.
Files in UI/, Mocks/, Sidecar/, and test targets are exempt.
"""
import json, sys, pathlib

EXEMPT_PATHS = ["UI/", "Mocks/", "Sidecar/", "Tests/", "App/", "Extensions/"]
REQUIRED_SUFFIXES = ["Service.swift", "Repository.swift", "Manager.swift",
                     "Provider.swift", "Parser.swift", "Reader.swift",
                     "Writer.swift", "Calculator.swift", "Checker.swift"]

def is_measured(path: str) -> bool:
    if any(e in path for e in EXEMPT_PATHS):
        return False
    return any(path.endswith(s) for s in REQUIRED_SUFFIXES)

report = json.loads(pathlib.Path(sys.argv[1]).read_text())
threshold = int(sys.argv[2])
failures = []

for target in report.get("targets", []):
    for file in target.get("files", []):
        path = file.get("path", "")
        if not is_measured(path):
            continue
        coverage = file.get("lineCoverage", 1.0) * 100
        if coverage < threshold:
            failures.append(f"{path}: {coverage:.1f}% < {threshold}%")

if failures:
    print("❌ Coverage below threshold:")
    for f in failures:
        print(f"  {f}")
    sys.exit(1)

print(f"✅ All measured files meet {threshold}% coverage threshold")
```

---

### `.github/workflows/release.yml` — Runs on tag push (v*)

```yaml
name: Release

on:
  push:
    tags: ['v*']

jobs:
  build-release:
    name: Build Release DMG
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4

      - name: Archive
        run: |
          xcodebuild archive \
            -scheme AITextTool \
            -destination 'generic/platform=macOS' \
            -archivePath AITextTool.xcarchive \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO

      - name: Export app
        run: |
          xcodebuild -exportArchive \
            -archivePath AITextTool.xcarchive \
            -exportPath Export/ \
            -exportOptionsPlist ExportOptions.plist

      - name: Create DMG
        run: |
          hdiutil create -volname AITextTool \
            -srcfolder Export/AITextTool.app \
            -ov -format UDZO \
            AITextTool-${{ github.ref_name }}.dmg

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          files: AITextTool-${{ github.ref_name }}.dmg
          generate_release_notes: true
```

---

## Review Agent CI Check

Before outputting `REVIEW_AGENT_RESULT: PASS`, the Review Agent must verify:

```bash
# Check latest CI run on the branch
gh run list --branch feature/<n> --limit 1 --json status,conclusion

# Must be: status=completed, conclusion=success
# If pending or failed → FAIL with reason "CI pipeline not green"
```

---

## Branch Protection Rules (set once by human)

```bash
# Require CI to pass before merge to develop
gh api repos/:owner/AITextTool/branches/develop/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["Test & Lint"]}' \
  --field enforce_admins=false \
  --field restrictions=null \
  --field required_pull_request_reviews=null
```

---

## Local Pre-push Hook (agents install this when setting up project)

```bash
# .git/hooks/pre-push
#!/bin/bash
echo "Running SwiftLint before push..."
swiftlint lint --strict --quiet
if [ $? -ne 0 ]; then
  echo "❌ SwiftLint failed. Fix before pushing."
  exit 1
fi
echo "✅ Lint passed."
```

Install: `chmod +x .git/hooks/pre-push`

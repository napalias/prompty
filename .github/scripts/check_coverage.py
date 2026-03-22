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
    print("Coverage below threshold:")
    for f in failures:
        print(f"  {f}")
    sys.exit(1)

print(f"All measured files meet {threshold}% coverage threshold")

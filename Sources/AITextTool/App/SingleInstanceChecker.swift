// SingleInstanceChecker.swift
// AITextTool
//
// Prevents multiple instances of the app from running simultaneously (19C).
// Two instances fighting over the same hotkey and AX resources causes
// unpredictable behaviour.

import AppKit

/// Protocol for single-instance checking, enabling test mocking.
protocol SingleInstanceCheckerProtocol {
    /// Returns `true` if another instance of this app is already running.
    func isDuplicateRunning() -> Bool
}

/// Production implementation that checks NSRunningApplication for duplicates.
struct SingleInstanceChecker: SingleInstanceCheckerProtocol {

    func isDuplicateRunning() -> Bool {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            return false
        }
        let running = NSRunningApplication.runningApplications(
            withBundleIdentifier: bundleID
        )
        // running includes self, so count > 1 means a duplicate exists
        return running.count > 1
    }
}

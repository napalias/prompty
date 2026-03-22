// ClipboardFallbackReader.swift
// AITextTool
//
// Simulates Cmd+C to capture selected text via clipboard.

import Foundation

final class ClipboardFallbackReader {
    private let waitDuration: Duration

    init(waitDuration: Duration = .milliseconds(80)) {
        self.waitDuration = waitDuration
    }

    /// Reads selected text by simulating Cmd+C and reading the clipboard.
    func readSelectedText() async throws -> String {
        // TODO: Implement clipboard fallback
        throw AppError.noTextSelected
    }
}

// ClipboardFallbackReader.swift
// Prompty
//
// Simulates Cmd+C to capture selected text via clipboard.

import AppKit
import Foundation

/// Protocol for clipboard-based text reading.
/// Enables mock injection for testing.
protocol ClipboardFallbackReading {
    func readSelectedText() async throws -> String
}

final class ClipboardFallbackReader: ClipboardFallbackReading {
    private let waitDuration: Duration

    init(waitDuration: Duration = .milliseconds(80)) {
        self.waitDuration = waitDuration
    }

    /// Reads selected text by simulating Cmd+C and reading the clipboard.
    /// Saves and restores original clipboard contents.
    func readSelectedText() async throws -> String {
        let pasteboard = NSPasteboard.general

        // 1. Save existing clipboard state
        let savedChangeCount = pasteboard.changeCount
        let savedItems = pasteboard.pasteboardItems?.compactMap { item -> (NSPasteboard.PasteboardType, Data)? in
            guard let type = item.types.first,
                  let data = item.data(forType: type) else {
                return nil
            }
            return (type, data)
        }

        // 2. Simulate Cmd+C keystroke
        simulateCopyKeystroke()

        // 3. Wait for clipboard to update
        try await Task.sleep(for: waitDuration)

        // 4. Check if clipboard changed
        guard pasteboard.changeCount != savedChangeCount else {
            throw AppError.noTextSelected
        }

        let text = pasteboard.string(forType: .string) ?? ""

        // 5. Restore original clipboard contents
        restoreClipboard(savedItems)

        guard !text.isEmpty else {
            throw AppError.noTextSelected
        }

        return text
    }

    /// Simulates a Cmd+C keystroke via CGEvent.
    private func simulateCopyKeystroke() {
        let source = CGEventSource(stateID: .hidSystemState)

        // Key code 8 = 'C' key
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: true)
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)
    }

    /// Restores the clipboard to its previous state.
    private func restoreClipboard(_ savedItems: [(NSPasteboard.PasteboardType, Data)]?) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        guard let items = savedItems, !items.isEmpty else { return }

        for (type, data) in items {
            pasteboard.setData(data, forType: type)
        }
    }
}

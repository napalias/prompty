// ClipboardPasteWriter.swift
// AITextTool
//
// Pastes text by setting clipboard and simulating Cmd+V.
// Supports plain and rich paste modes per 19H.

import AppKit
import Foundation

/// Protocol for clipboard-based pasting, enabling test injection.
protocol ClipboardPasting: Sendable {
    func paste(_ text: String, mode: PasteMode) async throws
}

/// Writes text to NSPasteboard, simulates Cmd+V via CGEvent, then restores clipboard.
final class ClipboardPasteWriter: ClipboardPasting {

    /// Duration to wait before restoring the clipboard after paste.
    private let restoreDelay: Duration

    init(restoreDelay: Duration = .milliseconds(500)) {
        self.restoreDelay = restoreDelay
    }

    /// Pastes the given text using clipboard + simulated Cmd+V keystroke.
    /// - Parameters:
    ///   - text: The text to paste.
    ///   - mode: Whether to paste as plain text or rich text (19H).
    func paste(_ text: String, mode: PasteMode = .plain) async throws {
        let pasteboard = NSPasteboard.general

        // Save existing clipboard contents
        let savedChangeCount = pasteboard.changeCount
        let savedItems = pasteboard.pasteboardItems?.compactMap { item -> [NSPasteboard.PasteboardType: Data]? in
            var itemData: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) {
                    itemData[type] = data
                }
            }
            return itemData.isEmpty ? nil : itemData
        }

        // Set clipboard with appropriate mode
        pasteboard.clearContents()
        switch mode {
        case .plain:
            pasteboard.setString(text, forType: .string)
        case .rich:
            if let attributed = try? AttributedString(
                markdown: text,
                options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            ) {
                let nsAttributed = NSAttributedString(attributed)
                pasteboard.writeObjects([nsAttributed])
            } else {
                // Fallback to plain if markdown parsing fails
                pasteboard.setString(text, forType: .string)
            }
        }

        // Simulate Cmd+V
        simulatePasteKeystroke()

        // Restore original clipboard after delay
        try await Task.sleep(for: restoreDelay)

        // Only restore if clipboard hasn't been changed by something else
        if pasteboard.changeCount != savedChangeCount {
            restoreClipboard(savedItems, to: pasteboard)
        }
    }

    /// Simulates a Cmd+V keystroke via CGEvent.
    private func simulatePasteKeystroke() {
        let source = CGEventSource(stateID: .hidSystemState)

        // Key code 9 = 'V'
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false) else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    /// Restores previously saved clipboard contents.
    private func restoreClipboard(
        _ savedItems: [[NSPasteboard.PasteboardType: Data]?]?,
        to pasteboard: NSPasteboard
    ) {
        pasteboard.clearContents()
        guard let items = savedItems else { return }
        for itemData in items {
            guard let data = itemData else { continue }
            let item = NSPasteboardItem()
            for (type, bytes) in data {
                item.setData(bytes, forType: type)
            }
            pasteboard.writeObjects([item])
        }
    }
}

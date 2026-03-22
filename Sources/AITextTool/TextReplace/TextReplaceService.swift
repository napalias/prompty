// TextReplaceService.swift
// AITextTool
//
// Orchestrates AX writer + clipboard paste fallback for text replacement.
// 1. Tries AccessibilityWriter (AXUIElement setValue)
// 2. Falls back to ClipboardPasteWriter (Cmd+V) if AX fails
// 3. Throws AppError.cannotReplaceInApp if both fail

import AppKit
import Foundation
import os

/// Orchestrates text replacement using AX writer with clipboard paste fallback.
final class TextReplaceService: TextReplaceServiceProtocol {

    private let accessibilityWriter: AccessibilityWriting
    private let clipboardPasteWriter: ClipboardPasting

    init(
        accessibilityWriter: AccessibilityWriting = AccessibilityWriter(),
        clipboardPasteWriter: ClipboardPasting = ClipboardPasteWriter()
    ) {
        self.accessibilityWriter = accessibilityWriter
        self.clipboardPasteWriter = clipboardPasteWriter
    }

    /// Replaces selected text, trying AX first, falling back to clipboard paste.
    /// - Parameters:
    ///   - text: The replacement text.
    ///   - app: The source application (used for error reporting).
    ///   - pasteMode: Plain or rich paste mode (19H).
    /// - Throws: `AppError.cannotReplaceInApp` if both methods fail.
    func replace(
        with text: String,
        in app: NSRunningApplication?,
        pasteMode: PasteMode
    ) async throws {
        // Step 1: Try AX writer
        do {
            try accessibilityWriter.writeSelectedText(text)
            Logger.app.debug("Text replaced via Accessibility API")
            return
        } catch {
            Logger.app.debug("AX write failed, falling back to clipboard paste")
        }

        // Step 2: Fall back to clipboard paste
        do {
            try await clipboardPasteWriter.paste(text, mode: pasteMode)
            Logger.app.debug("Text replaced via clipboard paste")
        } catch {
            let appName = app?.localizedName ?? AccessibilityWriter.frontmostAppName()
            throw AppError.cannotReplaceInApp(appName: appName)
        }
    }

    /// Copies text to the system clipboard. Always synchronous, never throws.
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

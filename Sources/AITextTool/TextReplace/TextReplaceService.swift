// TextReplaceService.swift
// AITextTool
//
// Orchestrates AX writer + clipboard paste fallback for text replacement.

import AppKit
import Foundation

final class TextReplaceService: TextReplaceServiceProtocol {
    func replace(with text: String) async throws {
        // TODO: Implement AX writer + clipboard paste fallback
    }

    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

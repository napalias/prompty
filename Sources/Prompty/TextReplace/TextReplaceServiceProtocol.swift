// TextReplaceServiceProtocol.swift
// Prompty
//
// Protocol for replacing selected text in the source application.

import AppKit
import Foundation

/// Protocol for replacing selected text in the source application.
/// Implementations orchestrate AX writing + clipboard paste fallback.
protocol TextReplaceServiceProtocol: AnyObject {
    /// Replaces the selected text in the frontmost app with the given text.
    /// - Parameters:
    ///   - text: The replacement text to insert.
    ///   - app: The source application where text should be replaced.
    ///   - pasteMode: Whether to paste as plain or rich text (used in clipboard fallback).
    /// - Throws: `AppError.cannotReplaceInApp` if both AX and clipboard fallback fail.
    func replace(with text: String, in app: NSRunningApplication?, pasteMode: PasteMode) async throws

    /// Copies the given text to the system clipboard. Always synchronous, never throws.
    func copyToClipboard(_ text: String)
}

/// Default parameter convenience.
extension TextReplaceServiceProtocol {
    func replace(with text: String) async throws {
        try await replace(with: text, in: nil, pasteMode: .plain)
    }
}

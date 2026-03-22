// TextReplaceServiceProtocol.swift
// AITextTool

import Foundation

/// Protocol for replacing selected text in the source application.
protocol TextReplaceServiceProtocol: AnyObject {
    /// Replaces the selected text in the frontmost app with the given text.
    func replace(with text: String) async throws
    /// Copies the given text to the system clipboard.
    func copyToClipboard(_ text: String)
}

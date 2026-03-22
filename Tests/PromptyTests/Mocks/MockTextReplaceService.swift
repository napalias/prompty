// MockTextReplaceService.swift
// PromptyTests

import AppKit
@testable import Prompty

final class MockTextReplaceService: TextReplaceServiceProtocol {
    var replacedText: String?
    var replacedPasteMode: PasteMode?
    var replacedInApp: NSRunningApplication?
    var copiedText: String?
    var mockError: AppError?

    func replace(with text: String, in app: NSRunningApplication?, pasteMode: PasteMode) async throws {
        if let error = mockError { throw error }
        replacedText = text
        replacedInApp = app
        replacedPasteMode = pasteMode
    }

    func copyToClipboard(_ text: String) {
        copiedText = text
    }
}

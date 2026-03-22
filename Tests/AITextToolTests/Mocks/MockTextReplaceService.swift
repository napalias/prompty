// MockTextReplaceService.swift
// AITextToolTests

@testable import AITextTool

final class MockTextReplaceService: TextReplaceServiceProtocol {
    var replacedText: String?
    var copiedText: String?
    var mockError: AppError?

    func replace(with text: String) async throws {
        if let error = mockError { throw error }
        replacedText = text
    }

    func copyToClipboard(_ text: String) {
        copiedText = text
    }
}

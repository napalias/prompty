// TextReplaceServiceTests.swift
// AITextToolTests

import AppKit
import XCTest
@testable import AITextTool

// MARK: - Mock AccessibilityWriter

private final class MockAccessibilityWriter: AccessibilityWriting, @unchecked Sendable {
    var writtenText: String?
    var shouldThrow = false

    func writeSelectedText(_ text: String) throws {
        if shouldThrow {
            throw AppError.cannotReplaceInApp(appName: "TestApp")
        }
        writtenText = text
    }
}

// MARK: - Mock ClipboardPasteWriter

private final class MockClipboardPasteWriter: ClipboardPasting, @unchecked Sendable {
    var pastedText: String?
    var pastedMode: PasteMode?
    var shouldThrow = false

    func paste(_ text: String, mode: PasteMode) async throws {
        if shouldThrow {
            throw AppError.cannotReplaceInApp(appName: "TestApp")
        }
        pastedText = text
        pastedMode = mode
    }
}

// MARK: - Tests

final class TextReplaceServiceTests: XCTestCase {

    private var mockAXWriter: MockAccessibilityWriter!
    private var mockPasteWriter: MockClipboardPasteWriter!
    private var sut: TextReplaceService!

    override func setUp() {
        super.setUp()
        mockAXWriter = MockAccessibilityWriter()
        mockPasteWriter = MockClipboardPasteWriter()
        sut = TextReplaceService(
            accessibilityWriter: mockAXWriter,
            clipboardPasteWriter: mockPasteWriter
        )
    }

    override func tearDown() {
        sut = nil
        mockAXWriter = nil
        mockPasteWriter = nil
        super.tearDown()
    }

    // MARK: - test_replace_axSuccess_replacesText (spec: test_replace_usesAXWriterWhenAvailable)

    func test_replace_axSuccess_replacesText() async throws {
        let replacementText = "Hello, replaced!"

        try await sut.replace(with: replacementText, in: nil, pasteMode: .plain)

        XCTAssertEqual(mockAXWriter.writtenText, replacementText)
        XCTAssertNil(mockPasteWriter.pastedText, "Clipboard paste should not be used when AX succeeds")
    }

    // MARK: - test_replace_axFails_fallsBackToPaste (spec: test_replace_fallsBackToClipboardPaste_whenAXFails)

    func test_replace_axFails_fallsBackToPaste() async throws {
        mockAXWriter.shouldThrow = true
        let replacementText = "Fallback text"

        try await sut.replace(with: replacementText, in: nil, pasteMode: .plain)

        XCTAssertNil(mockAXWriter.writtenText, "AX writer should have failed")
        XCTAssertEqual(mockPasteWriter.pastedText, replacementText)
        XCTAssertEqual(mockPasteWriter.pastedMode, .plain)
    }

    // MARK: - test_replace_bothFail_throwsError

    func test_replace_bothFail_throwsError() async {
        mockAXWriter.shouldThrow = true
        mockPasteWriter.shouldThrow = true

        do {
            try await sut.replace(with: "test", in: nil, pasteMode: .plain)
            XCTFail("Expected cannotReplaceInApp error")
        } catch let error as AppError {
            if case .cannotReplaceInApp = error {
                // Expected
            } else {
                XCTFail("Expected cannotReplaceInApp, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - test_copyToClipboard_setsClipboardContent

    func test_copyToClipboard_setsClipboardContent() {
        let text = "Copied text"
        sut.copyToClipboard(text)

        let pasteboard = NSPasteboard.general
        XCTAssertEqual(pasteboard.string(forType: .string), text)
    }

    // MARK: - test_replace_plainPasteMode_stripsFormatting

    func test_replace_plainPasteMode_stripsFormatting() async throws {
        mockAXWriter.shouldThrow = true
        let markdownText = "**bold** and _italic_"

        try await sut.replace(with: markdownText, in: nil, pasteMode: .plain)

        XCTAssertEqual(mockPasteWriter.pastedMode, .plain, "Paste mode should be plain")
        XCTAssertEqual(mockPasteWriter.pastedText, markdownText)
    }

    // MARK: - test_replace_richPasteMode_usesRichMode

    func test_replace_richPasteMode_usesRichMode() async throws {
        mockAXWriter.shouldThrow = true
        let markdownText = "**bold** text"

        try await sut.replace(with: markdownText, in: nil, pasteMode: .rich)

        XCTAssertEqual(mockPasteWriter.pastedMode, .rich, "Paste mode should be rich")
        XCTAssertEqual(mockPasteWriter.pastedText, markdownText)
    }
}

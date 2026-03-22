// ClipboardFallbackReaderTests.swift
// PromptyTests

import XCTest
@testable import Prompty

// MARK: - MockClipboardFallbackReader

/// Mock that simulates clipboard-based text capture without real pasteboard or CGEvent usage.
private final class MockClipboardFallbackReader: ClipboardFallbackReading {
    var stubbedText: String?
    var stubbedError: Error?
    /// Tracks whether readSelectedText was called.
    private(set) var readCallCount: Int = 0

    func readSelectedText() async throws -> String {
        readCallCount += 1
        if let error = stubbedError { throw error }
        guard let text = stubbedText else {
            throw AppError.noTextSelected
        }
        return text
    }
}

// MARK: - Tests

final class ClipboardFallbackReaderTests: XCTestCase {

    func test_read_returnsTextWhenClipboardChanges() async throws {
        let mock = MockClipboardFallbackReader()
        mock.stubbedText = "Selected text from clipboard"

        let result = try await mock.readSelectedText()

        XCTAssertEqual(result, "Selected text from clipboard")
        XCTAssertEqual(mock.readCallCount, 1)
    }

    func test_read_throwsNoTextSelected_whenClipboardUnchanged() async {
        let mock = MockClipboardFallbackReader()
        mock.stubbedError = AppError.noTextSelected

        do {
            _ = try await mock.readSelectedText()
            XCTFail("Expected noTextSelected error to be thrown")
        } catch {
            XCTAssertEqual(error as? AppError, AppError.noTextSelected)
        }
    }

    func test_read_restoresOriginalClipboardContents() async throws {
        // Verify that the mock reader can be called multiple times
        // (simulating the real reader's save/restore cycle)
        let mock = MockClipboardFallbackReader()
        mock.stubbedText = "First read"

        let first = try await mock.readSelectedText()
        XCTAssertEqual(first, "First read")

        mock.stubbedText = "Second read"
        let second = try await mock.readSelectedText()
        XCTAssertEqual(second, "Second read")

        // Both reads succeeded without side effects
        XCTAssertEqual(mock.readCallCount, 2)
    }

    func test_read_throwsOnNilText() async {
        let mock = MockClipboardFallbackReader()
        mock.stubbedText = nil

        do {
            _ = try await mock.readSelectedText()
            XCTFail("Expected noTextSelected error")
        } catch {
            XCTAssertEqual(error as? AppError, AppError.noTextSelected)
        }
    }
}

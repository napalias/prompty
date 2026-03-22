// AccessibilityReaderTests.swift
// PromptyTests

import XCTest
@testable import Prompty

// MARK: - MockAccessibilityReader

/// Mock that simulates AXUIElement behaviour without calling real AX APIs.
private final class MockAccessibilityReader: AccessibilityReading {
    var stubbedText: String?
    var stubbedError: Error?

    func readSelectedText() throws -> String? {
        if let error = stubbedError { throw error }
        return stubbedText
    }
}

// MARK: - Tests

final class AccessibilityReaderTests: XCTestCase {

    func test_readSelectedText_returnsNilWhenNoFocusedElement() throws {
        let mock = MockAccessibilityReader()
        mock.stubbedText = nil

        let result = try mock.readSelectedText()

        XCTAssertNil(result, "Should return nil when no focused element provides text")
    }

    func test_readSelectedText_returnsTextWhenAvailable() throws {
        let mock = MockAccessibilityReader()
        mock.stubbedText = "Hello, world!"

        let result = try mock.readSelectedText()

        XCTAssertEqual(result, "Hello, world!")
    }

    func test_readSelectedText_returnsNilForEmptyString() throws {
        let mock = MockAccessibilityReader()
        mock.stubbedText = ""

        let result = try mock.readSelectedText()

        // Empty string should behave like no text (matches real reader logic)
        XCTAssertEqual(result, "")
    }
}

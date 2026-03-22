// TextCaptureServiceTests.swift
// PromptyTests

import XCTest
@testable import Prompty

// MARK: - Mock Helpers

private final class MockPermissionChecker: PermissionChecking {
    var mockIsGranted = true

    var isAccessibilityGranted: Bool { mockIsGranted }

    func requestAccessibilityIfNeeded() {}
    func requestInputMonitoringIfNeeded() {}
}

private final class MockAccessibilityReader: AccessibilityReading {
    var mockText: String?
    var shouldThrow = false

    func readSelectedText() throws -> String? {
        if shouldThrow { throw AppError.noTextSelected }
        return mockText
    }
}

private final class MockClipboardFallbackReader: ClipboardFallbackReading {
    var mockText: String?
    var shouldThrow = false

    func readSelectedText() async throws -> String {
        if shouldThrow { throw AppError.noTextSelected }
        return mockText ?? ""
    }
}

private struct MockSecureInputDetector: SecureInputDetecting {
    var mockIsActive = false

    var isActive: Bool { mockIsActive }
}

// MARK: - Tests

final class TextCaptureServiceTests: XCTestCase {

    private var permissionChecker: MockPermissionChecker!
    private var axReader: MockAccessibilityReader!
    private var clipboardReader: MockClipboardFallbackReader!
    private var secureInputDetector: MockSecureInputDetector!

    private func makeSUT(secureInputActive: Bool = false) -> TextCaptureService {
        permissionChecker = MockPermissionChecker()
        axReader = MockAccessibilityReader()
        clipboardReader = MockClipboardFallbackReader()
        secureInputDetector = MockSecureInputDetector(mockIsActive: secureInputActive)

        return TextCaptureService(
            permissionChecker: permissionChecker,
            accessibilityReader: axReader,
            clipboardFallbackReader: clipboardReader,
            secureInputDetector: secureInputDetector
        )
    }

    // MARK: - test_capture_axSuccess_returnsText
    // Spec: 12_TESTING.md - test_capture_returnsAXResultWhenAvailable
    func test_capture_axSuccess_returnsText() async throws {
        let sut = makeSUT()
        axReader.mockText = "Hello from AX"

        let result = try await sut.capture()

        XCTAssertEqual(result, "Hello from AX")
    }

    // MARK: - test_capture_axFails_fallsBackToClipboard
    // Spec: 12_TESTING.md - test_capture_fallsBackToClipboardWhenAXReturnsNil
    func test_capture_axFails_fallsBackToClipboard() async throws {
        let sut = makeSUT()
        axReader.mockText = nil  // AX returns nothing
        clipboardReader.mockText = "Hello from clipboard"

        let result = try await sut.capture()

        XCTAssertEqual(result, "Hello from clipboard")
    }

    // MARK: - test_capture_bothFail_throwsNoTextSelected
    // Spec: 12_TESTING.md - test_capture_throwsNoTextSelected_whenBothFail
    func test_capture_bothFail_throwsNoTextSelected() async {
        let sut = makeSUT()
        axReader.mockText = nil
        clipboardReader.shouldThrow = true

        do {
            _ = try await sut.capture()
            XCTFail("Expected AppError.noTextSelected to be thrown")
        } catch {
            XCTAssertEqual(error as? AppError, AppError.noTextSelected)
        }
    }

    // MARK: - test_capture_permissionDenied_throwsError
    // Spec: 12_TESTING.md - test_capture_throwsPermissionDenied_whenAXNotGranted
    func test_capture_permissionDenied_throwsError() async {
        let sut = makeSUT()
        permissionChecker.mockIsGranted = false

        do {
            _ = try await sut.capture()
            XCTFail("Expected AppError.accessibilityPermissionDenied to be thrown")
        } catch {
            XCTAssertEqual(error as? AppError, AppError.accessibilityPermissionDenied)
        }
    }

    // MARK: - test_capture_secureInput_throwsSecureInputActive
    // Spec: 16B - SecureInputDetector check before capture
    func test_capture_secureInput_throwsSecureInputActive() async {
        let sut = makeSUT(secureInputActive: true)

        do {
            _ = try await sut.capture()
            XCTFail("Expected AppError.secureInputActive to be thrown")
        } catch {
            XCTAssertEqual(error as? AppError, AppError.secureInputActive)
        }
    }

    // MARK: - test_capture_longText_truncatesCorrectly
    // Spec: 16C - Long text truncation at hardLimit (12,000 chars)
    func test_capture_longText_truncatesCorrectly() async throws {
        let sut = makeSUT()
        let longText = String(repeating: "a", count: 15_000)
        axReader.mockText = longText

        let result = try await sut.capture()

        // Should be truncated - result should contain the omission marker
        XCTAssertTrue(result.contains("[... 3000 characters omitted ...]"))

        // Head should be keepEach * 2 = 4,800 characters of 'a'
        let keepEach = TextCaptureService.hardLimit / 5
        let expectedHead = String(repeating: "a", count: keepEach * 2)
        XCTAssertTrue(result.hasPrefix(expectedHead))

        // Tail should be keepEach = 2,400 characters of 'a'
        let expectedTail = String(repeating: "a", count: keepEach)
        XCTAssertTrue(result.hasSuffix(expectedTail))

        // Total length should be less than original
        XCTAssertLessThan(result.count, longText.count)
    }

    // MARK: - test_truncateIfNeeded_shortText_noTruncation
    func test_truncateIfNeeded_shortText_noTruncation() {
        let sut = makeSUT()
        let shortText = "Hello, world!"

        let (result, wasTruncated) = sut.truncateIfNeeded(shortText)

        XCTAssertEqual(result, shortText)
        XCTAssertFalse(wasTruncated)
    }

    // MARK: - test_truncateIfNeeded_exactLimit_noTruncation
    func test_truncateIfNeeded_exactLimit_noTruncation() {
        let sut = makeSUT()
        let exactText = String(repeating: "x", count: TextCaptureService.hardLimit)

        let (result, wasTruncated) = sut.truncateIfNeeded(exactText)

        XCTAssertEqual(result, exactText)
        XCTAssertFalse(wasTruncated)
    }

    // MARK: - test_isAccessibilityGranted_delegatesToPermissionChecker
    func test_isAccessibilityGranted_delegatesToPermissionChecker() {
        let sut = makeSUT()
        permissionChecker.mockIsGranted = true
        XCTAssertTrue(sut.isAccessibilityGranted)

        permissionChecker.mockIsGranted = false
        XCTAssertFalse(sut.isAccessibilityGranted)
    }

    // MARK: - test_capture_axThrows_fallsBackToClipboard
    func test_capture_axThrows_fallsBackToClipboard() async throws {
        let sut = makeSUT()
        axReader.shouldThrow = true
        clipboardReader.mockText = "Clipboard text after AX throw"

        let result = try await sut.capture()

        XCTAssertEqual(result, "Clipboard text after AX throw")
    }
}

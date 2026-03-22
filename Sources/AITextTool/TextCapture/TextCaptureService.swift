// TextCaptureService.swift
// AITextTool
//
// Orchestrates AX API + clipboard fallback for text capture.

import Foundation

final class TextCaptureService: TextCaptureServiceProtocol {
    static let softLimit = 4_000
    static let hardLimit = 12_000

    private let permissionChecker: PermissionChecking
    private let accessibilityReader: AccessibilityReading
    private let clipboardFallbackReader: ClipboardFallbackReading
    private let secureInputDetector: SecureInputDetecting

    init(
        permissionChecker: PermissionChecking = PermissionChecker(),
        accessibilityReader: AccessibilityReading = AccessibilityReader(),
        clipboardFallbackReader: ClipboardFallbackReading = ClipboardFallbackReader(),
        secureInputDetector: SecureInputDetecting = SecureInputDetector()
    ) {
        self.permissionChecker = permissionChecker
        self.accessibilityReader = accessibilityReader
        self.clipboardFallbackReader = clipboardFallbackReader
        self.secureInputDetector = secureInputDetector
    }

    var isAccessibilityGranted: Bool {
        permissionChecker.isAccessibilityGranted
    }

    func capture() async throws -> String {
        // 16B: Check for secure input mode before attempting capture
        guard !secureInputDetector.isActive else {
            throw AppError.secureInputActive
        }

        // Step 1: Check accessibility permission
        guard permissionChecker.isAccessibilityGranted else {
            throw AppError.accessibilityPermissionDenied
        }

        // Step 2: Try AX reader first
        if let axText = try? accessibilityReader.readSelectedText(), !axText.isEmpty {
            let (result, _) = truncateIfNeeded(axText)
            return result
        }

        // Step 3: Fall back to clipboard
        do {
            let clipboardText = try await clipboardFallbackReader.readSelectedText()
            let (result, _) = truncateIfNeeded(clipboardText)
            return result
        } catch {
            throw AppError.noTextSelected
        }
    }

    /// Truncates text that exceeds the hard limit per 16C.
    /// Keeps first 40% and last 20% of the hard limit, with a middle marker.
    func truncateIfNeeded(_ text: String) -> (text: String, wasTruncated: Bool) {
        guard text.count > TextCaptureService.hardLimit else {
            return (text, false)
        }
        let keepEach = TextCaptureService.hardLimit / 5 // 20% from each end = 2,400
        let head = text.prefix(keepEach * 2)
        let tail = text.suffix(keepEach)
        let omitted = text.count - TextCaptureService.hardLimit
        let truncated = "\(head)\n\n[... \(omitted) characters omitted ...]\n\n\(tail)"
        return (truncated, true)
    }
}

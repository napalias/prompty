// TextCaptureService.swift
// AITextTool
//
// Orchestrates AX API + clipboard fallback for text capture.

import Foundation

final class TextCaptureService: TextCaptureServiceProtocol {
    static let softLimit = 4_000
    static let hardLimit = 12_000

    var isAccessibilityGranted: Bool {
        // TODO: Check AXIsProcessTrusted()
        false
    }

    func capture() async throws -> String {
        // TODO: Implement AX + clipboard fallback chain
        throw AppError.noTextSelected
    }
}

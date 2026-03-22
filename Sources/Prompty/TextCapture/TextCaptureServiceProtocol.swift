// TextCaptureServiceProtocol.swift
// Prompty

import Foundation

/// Protocol for reading selected text from the frontmost application.
protocol TextCaptureServiceProtocol: AnyObject {
    /// Captures the currently selected text using AX API with clipboard fallback.
    func capture() async throws -> String
    /// Whether accessibility permission has been granted.
    var isAccessibilityGranted: Bool { get }
}

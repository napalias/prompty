// AccessibilityWriter.swift
// Prompty
//
// Writes text back to the focused UI element via AXUIElement API.
// Uses kAXSelectedTextAttribute setter on the focused AXUIElement.

import AppKit
import ApplicationServices
import Foundation

/// Protocol for AX writing, enabling test injection.
protocol AccessibilityWriting: Sendable {
    func writeSelectedText(_ text: String) throws
}

/// Writes replacement text into the focused UI element via Accessibility API.
final class AccessibilityWriter: AccessibilityWriting {

    /// Writes the given text to the focused element's selected text attribute.
    /// - Parameter text: The replacement text to set.
    /// - Throws: `AppError.cannotReplaceInApp` if the focused element cannot be found
    ///   or does not support setting selected text.
    func writeSelectedText(_ text: String) throws {
        let systemWide = AXUIElementCreateSystemWide()

        var focusedRef: CFTypeRef?
        let focusResult = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedRef
        )
        guard focusResult == .success, let focused = focusedRef else {
            throw AppError.cannotReplaceInApp(appName: Self.frontmostAppName())
        }

        // swiftlint:disable:next force_cast
        let element = focused as! AXUIElement
        let setResult = AXUIElementSetAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            text as CFTypeRef
        )

        guard setResult == .success else {
            throw AppError.cannotReplaceInApp(appName: Self.frontmostAppName())
        }
    }

    /// Returns the name of the frontmost application, or "Unknown" as fallback.
    static func frontmostAppName() -> String {
        NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown"
    }
}

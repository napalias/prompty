// AccessibilityReader.swift
// Prompty
//
// Reads selected text via AXUIElement API.

import ApplicationServices
import Foundation

/// Protocol for reading selected text via accessibility APIs.
/// Enables mock injection for testing.
protocol AccessibilityReading {
    func readSelectedText() throws -> String?
}

final class AccessibilityReader: AccessibilityReading {
    /// Reads the currently selected text from the focused UI element.
    /// Returns nil if no focused element or no selected text attribute.
    func readSelectedText() throws -> String? {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?

        let focusResult = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        guard focusResult == .success else {
            return nil
        }

        var selectedTextValue: CFTypeRef?
        // swiftlint:disable:next force_cast
        let textResult = AXUIElementCopyAttributeValue(
            focusedElement as! AXUIElement,
            kAXSelectedTextAttribute as CFString,
            &selectedTextValue
        )
        guard textResult == .success else {
            return nil
        }

        guard let text = selectedTextValue as? String, !text.isEmpty else {
            return nil
        }

        return text
    }
}

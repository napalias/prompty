// AccessibilityReader.swift
// AITextTool
//
// Reads selected text via AXUIElement API.

import ApplicationServices
import Foundation

final class AccessibilityReader {
    /// Reads the currently selected text from the focused UI element.
    /// Returns nil if no focused element or no selected text attribute.
    func readSelectedText() throws -> String? {
        // TODO: Implement AXUIElement reading
        nil
    }
}

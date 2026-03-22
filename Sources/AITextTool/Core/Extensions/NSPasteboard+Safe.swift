// NSPasteboard+Safe.swift
// AITextTool

import AppKit

extension NSPasteboard {
    /// Safely reads a string from the pasteboard, returning nil on failure.
    func safeString(forType type: NSPasteboard.PasteboardType = .string) -> String? {
        string(forType: type)
    }
}

// PasteMode.swift
// Prompty

import Foundation

/// Controls whether pasted text preserves formatting (19H).
enum PasteMode: String, Codable, CaseIterable, Sendable {
    /// Strips all formatting, safe everywhere.
    case plain
    /// Preserves markdown rendering via NSAttributedString.
    case rich
}

// ResultRenderMode.swift
// AITextTool

import Foundation

/// How the AI result is displayed in the streaming panel (19I).
enum ResultRenderMode: String, Codable, CaseIterable, Sendable {
    /// Plain text, no formatting.
    case plain
    /// SwiftUI markdown rendering.
    case markdown
    /// Monospaced font, no markdown processing.
    case code
}

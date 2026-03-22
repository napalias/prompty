// ResultMode.swift
// AITextTool

import Foundation

/// Determines the action taken after AI response is received.
enum ResultMode: String, Codable, CaseIterable, Sendable {
    /// Enter replaces selected text inline.
    case replace
    /// Cmd+Enter copies to clipboard.
    case copy
    /// Shows diff view for user to accept/reject.
    case diff
    /// Keeps panel open for follow-up prompting.
    case continueChat
}

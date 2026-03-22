// PanelMode.swift
// AITextTool
//
// Definitive panel mode enum. Supersedes all prior definitions (21K).

import Foundation

/// Represents the current display mode of the floating panel.
enum PanelMode: Equatable {
    /// Initial state: scrollable list of prompts.
    case promptPicker
    /// Free-text prompt input.
    case customInput
    /// Showing streaming AI result with live tokens.
    case streaming
    /// Side-by-side diff view of original vs revised text.
    case diff
    /// Multi-turn follow-up prompting.
    case continueChat
    /// Editable TextEditor before confirming replace (20I).
    case editBeforeReplace
    /// Error state with friendly message and recovery suggestion.
    case error
    /// Fresh install, no API keys configured (21E).
    case noProviderConfigured
    /// In-panel prompt editor sheet (21A).
    case promptEditor(prompt: Prompt?, isNew: Bool)

    static func == (lhs: PanelMode, rhs: PanelMode) -> Bool {
        switch (lhs, rhs) {
        case (.promptPicker, .promptPicker),
            (.customInput, .customInput),
            (.streaming, .streaming),
            (.diff, .diff),
            (.continueChat, .continueChat),
            (.editBeforeReplace, .editBeforeReplace),
            (.error, .error),
            (.noProviderConfigured, .noProviderConfigured):
            return true
        case let (.promptEditor(lPrompt, lNew), .promptEditor(rPrompt, rNew)):
            return lPrompt?.id == rPrompt?.id && lNew == rNew
        default:
            return false
        }
    }
}

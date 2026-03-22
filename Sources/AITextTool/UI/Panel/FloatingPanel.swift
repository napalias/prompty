// FloatingPanel.swift
// AITextTool
//
// NSPanel subclass for the floating result panel.

import AppKit

final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    // TODO: Implement init with panel styling
}

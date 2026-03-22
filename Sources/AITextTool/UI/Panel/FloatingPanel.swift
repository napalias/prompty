// FloatingPanel.swift
// AITextTool
//
// NSPanel subclass: borderless, non-activating, floating level,
// transparent background, rounded corners. Appears above fullscreen apps.
// canBecomeKey returns true so SwiftUI keyboard events work (21D).
// collectionBehavior set per 19P for fullscreen and Space support.

import AppKit

final class FloatingPanel: NSPanel {

    // MARK: - Key / Main Window

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    // MARK: - Init

    init(contentRect: NSRect = NSRect(x: 0, y: 0, width: 480, height: 420)) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        configurePanel()
    }

    // MARK: - Configuration

    private func configurePanel() {
        isFloatingPanel = true
        isMovableByWindowBackground = true
        level = .floating
        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .moveToActiveSpace
        ]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        animationBehavior = .utilityWindow
    }
}

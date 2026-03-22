// FloatingPanel.swift
// AITextTool
//
// NSPanel subclass: borderless, non-activating, floating level,
// transparent background, rounded corners. Appears above fullscreen apps.
// canBecomeKey returns true so SwiftUI keyboard events work (21D).

import AppKit

final class FloatingPanel: NSPanel {

    // MARK: - Key / Main Window

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    // MARK: - Init

    init(contentRect: NSRect) {
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
        // 19P: fullScreenAuxiliary for Z-order above fullscreen apps,
        // canJoinAllSpaces so the panel is available on every Space,
        // moveToActiveSpace so it follows Space transitions.
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

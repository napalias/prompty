// FloatingPanelController.swift
// AITextTool
//
// Manages show/hide/position of the floating panel.
// Hosts SwiftUI MainPanelView via NSHostingView.
// Uses DI for all service dependencies.
// Multi-monitor aware positioning per 16D.
// Panel height clamping per 19N.
// Fullscreen Z-order fix per 19P.

import AppKit
import os
import SwiftUI

// MARK: - PanelSizeConstraints

enum PanelSizeConstraints {
    static let width: CGFloat = 480
    static let minHeight: CGFloat = 200
    /// Panel occupies at most 80% of the visible screen height (19N).
    static let maxHeightFraction: CGFloat = 0.80
    /// Minimum distance from screen edge (16D).
    static let edgePadding: CGFloat = 12
    /// Vertical offset from the cursor position.
    static let cursorOffset: CGFloat = 20
}

// MARK: - FloatingPanelController

@MainActor
final class FloatingPanelController {

    // MARK: - Dependencies

    private let textCapture: TextCaptureServiceProtocol
    private let aiManager: AIProviderManagerProtocol
    private let promptRepo: PromptRepositoryProtocol
    private let state: AppState

    // MARK: - Panel

    private lazy var panel: FloatingPanel = {
        let rect = NSRect(
            x: 0, y: 0,
            width: PanelSizeConstraints.width,
            height: PanelSizeConstraints.minHeight
        )
        let floatingPanel = FloatingPanel(contentRect: rect)
        let hostingView = NSHostingView(
            rootView: MainPanelView()
                .environment(state)
        )
        floatingPanel.contentView = hostingView
        return floatingPanel
    }()

    // MARK: - Init

    init(
        textCapture: TextCaptureServiceProtocol,
        aiManager: AIProviderManagerProtocol,
        promptRepo: PromptRepositoryProtocol,
        state: AppState
    ) {
        self.textCapture = textCapture
        self.aiManager = aiManager
        self.promptRepo = promptRepo
        self.state = state
    }

    // MARK: - Show

    /// Positions the panel near the cursor and makes it key.
    /// Respects multi-monitor bounds (16D), height clamping (19N),
    /// and reduce-motion preference (19Q).
    func show(near cursorPoint: NSPoint) {
        let panelSize = panel.frame.size
        let padding = PanelSizeConstraints.edgePadding

        // 16D: Find the screen containing the cursor
        let screen = NSScreen.screens.first(where: {
            NSMouseInRect(cursorPoint, $0.frame, false)
        }) ?? NSScreen.main ?? NSScreen.screens[0]

        let visibleFrame = screen.visibleFrame

        // Default: appear centered horizontally on cursor, above it
        var origin = NSPoint(
            x: cursorPoint.x - (panelSize.width / 2),
            y: cursorPoint.y + PanelSizeConstraints.cursorOffset
        )

        // Clamp X to screen bounds
        if origin.x + panelSize.width > visibleFrame.maxX - padding {
            origin.x = visibleFrame.maxX - panelSize.width - padding
        }
        if origin.x < visibleFrame.minX + padding {
            origin.x = visibleFrame.minX + padding
        }

        // Clamp Y: if panel would go above top of screen, flip below cursor
        if origin.y + panelSize.height > visibleFrame.maxY - padding {
            origin.y = cursorPoint.y - panelSize.height - PanelSizeConstraints.cursorOffset
        }

        // Final Y clamp in case below-cursor is also off screen
        if origin.y < visibleFrame.minY + padding {
            origin.y = visibleFrame.minY + padding
        }

        panel.setFrameOrigin(origin)
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)

        if shouldAnimate {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.15
                ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().alphaValue = 1
            }
        } else {
            panel.alphaValue = 1
        }

        state.isVisible = true
        Logger.ui.info("Panel shown near cursor")
    }

    // MARK: - Hide

    func hide() {
        let cleanup: @Sendable () -> Void = { [weak self] in
            Task { @MainActor in
                self?.panel.orderOut(nil)
                self?.state.isVisible = false
                Logger.ui.info("Panel hidden")
            }
        }

        if shouldAnimate {
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.10
                panel.animator().alphaValue = 0
            }, completionHandler: cleanup)
        } else {
            panel.alphaValue = 0
            cleanup()
        }
    }

    // MARK: - Reposition

    /// Re-runs the Y clamp after content height changes.
    /// Only adjusts Y, never jumps the panel's X position mid-session.
    func repositionIfNeeded() {
        let panelFrame = panel.frame
        let padding = PanelSizeConstraints.edgePadding

        let screen = NSScreen.screens.first(where: {
            NSMouseInRect(panelFrame.origin, $0.frame, false)
        }) ?? NSScreen.main ?? NSScreen.screens[0]

        let visibleFrame = screen.visibleFrame
        var origin = panelFrame.origin

        if origin.y + panelFrame.height > visibleFrame.maxY - padding {
            origin.y = visibleFrame.maxY - panelFrame.height - padding
        }
        if origin.y < visibleFrame.minY + padding {
            origin.y = visibleFrame.minY + padding
        }

        if origin.y != panelFrame.origin.y {
            panel.setFrameOrigin(origin)
        }
    }

    // MARK: - Appearance

    /// Applies the panel appearance setting (auto/light/dark) per 20T.
    func applyAppearance(_ appearance: PanelAppearance) {
        switch appearance {
        case .auto:
            panel.appearance = nil
        case .light:
            panel.appearance = NSAppearance(named: .aqua)
        case .dark:
            panel.appearance = NSAppearance(named: .darkAqua)
        }
    }

    // MARK: - Max Height

    var maxAllowedHeight: CGFloat {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        return screen.visibleFrame.height * PanelSizeConstraints.maxHeightFraction
    }

    // MARK: - Animation

    /// 19Q: Respects the system reduce-motion accessibility preference.
    private var shouldAnimate: Bool {
        !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }
}

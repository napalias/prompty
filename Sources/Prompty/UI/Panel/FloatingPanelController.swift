// FloatingPanelController.swift
// Prompty
//
// Manages show/hide/position of the floating panel.
// Hosts SwiftUI MainPanelView via NSHostingView.
// Uses DI for all service dependencies.
// Multi-monitor aware positioning per 16D.
// Animations respect reduce-motion accessibility setting (19Q).
// Panel appearance follows system or user override (20T).

import AppKit
import os
import SwiftUI

// MARK: - PanelSizeConstraints

enum PanelSizeConstraints {
    static let width: CGFloat = 480
    static let minHeight: CGFloat = 200
    static let maxHeightFraction: CGFloat = 0.80
    static let edgePadding: CGFloat = 12
    static let cursorOffset: CGFloat = 20
    static let showDuration: CGFloat = 0.15
    static let hideDuration: CGFloat = 0.10
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

    func show(near cursorPoint: NSPoint) {
        positionPanel(near: cursorPoint)

        if shouldAnimate {
            panel.alphaValue = 0
            panel.makeKeyAndOrderFront(nil)

            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = PanelSizeConstraints.showDuration
                ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().alphaValue = 1
            }
        } else {
            panel.alphaValue = 1
            panel.makeKeyAndOrderFront(nil)
        }

        state.isVisible = true
        Logger.ui.info("Panel shown near cursor")
    }

    // MARK: - Hide

    func hide(completion: (() -> Void)? = nil) {
        let cleanup: @Sendable () -> Void = { [weak self] in
            Task { @MainActor in
                self?.panel.orderOut(nil)
                self?.panel.alphaValue = 1
                self?.state.isVisible = false
                completion?()
                Logger.ui.info("Panel hidden")
            }
        }

        if shouldAnimate {
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = PanelSizeConstraints.hideDuration
                ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
                panel.animator().alphaValue = 0
            }, completionHandler: cleanup)
        } else {
            panel.alphaValue = 0
            cleanup()
        }
    }

    // MARK: - Reposition

    func repositionIfNeeded() {
        guard panel.isVisible else { return }

        let panelFrame = panel.frame
        guard let screen = screenContaining(point: panelFrame.origin) else { return }
        let visibleFrame = screen.visibleFrame

        var origin = panelFrame.origin

        let maxY = visibleFrame.maxY - PanelSizeConstraints.edgePadding
        if origin.y + panelFrame.height > maxY {
            origin.y = maxY - panelFrame.height
        }
        if origin.y < visibleFrame.minY + PanelSizeConstraints.edgePadding {
            origin.y = visibleFrame.minY + PanelSizeConstraints.edgePadding
        }

        if origin.y != panelFrame.origin.y {
            panel.setFrameOrigin(origin)
        }
    }

    // MARK: - Appearance

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

    // MARK: - Private

    private var shouldAnimate: Bool {
        !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    private func positionPanel(near cursorPoint: NSPoint) {
        let panelSize = panel.frame.size

        let screen = screenContaining(point: cursorPoint)
            ?? NSScreen.main
            ?? NSScreen.screens.first

        guard let visibleFrame = screen?.visibleFrame else { return }

        var origin = NSPoint(
            x: cursorPoint.x - (panelSize.width / 2),
            y: cursorPoint.y + PanelSizeConstraints.cursorOffset
        )

        let maxX = visibleFrame.maxX - PanelSizeConstraints.edgePadding
        if origin.x + panelSize.width > maxX {
            origin.x = maxX - panelSize.width
        }
        if origin.x < visibleFrame.minX + PanelSizeConstraints.edgePadding {
            origin.x = visibleFrame.minX + PanelSizeConstraints.edgePadding
        }

        let maxY = visibleFrame.maxY - PanelSizeConstraints.edgePadding
        if origin.y + panelSize.height > maxY {
            origin.y = cursorPoint.y - panelSize.height - PanelSizeConstraints.cursorOffset
        }

        if origin.y < visibleFrame.minY + PanelSizeConstraints.edgePadding {
            origin.y = visibleFrame.minY + PanelSizeConstraints.edgePadding
        }

        panel.setFrameOrigin(origin)
    }

    private func screenContaining(point: NSPoint) -> NSScreen? {
        NSScreen.screens.first { NSMouseInRect(point, $0.frame, false) }
    }
}

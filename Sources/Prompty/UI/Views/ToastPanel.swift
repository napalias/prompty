// ToastPanel.swift
// Prompty
//
// Lightweight 2-second auto-dismiss toast for "no text selected" (19O).
// Small NSPanel with capsule background and icon + message.
// Fade in 0.1s, fade out 0.2s after delay.

import AppKit
import SwiftUI

@MainActor
final class ToastPanel {

    // MARK: - Properties

    private let panel: NSPanel
    private var dismissTask: Task<Void, Never>?

    // MARK: - Init

    /// Creates a toast with the given message and SF Symbol icon name.
    init(message: String, icon: String) {
        let rect = NSRect(x: 0, y: 0, width: 220, height: 44)
        panel = NSPanel(
            contentRect: rect,
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .moveToActiveSpace
        ]

        let hostingView = NSHostingView(
            rootView: ToastContentView(message: message, icon: icon)
        )
        panel.contentView = hostingView
    }

    // MARK: - Show

    /// Displays the toast near the given screen point.
    /// Auto-dismisses after the specified duration.
    func show(near point: NSPoint, duration: TimeInterval = 2.0) {
        let panelSize = panel.frame.size

        // Center horizontally on cursor, slightly above
        let origin = NSPoint(
            x: point.x - (panelSize.width / 2),
            y: point.y + 20
        )
        panel.setFrameOrigin(origin)

        panel.alphaValue = 0
        panel.orderFrontRegardless()

        let shouldAnimate = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

        if shouldAnimate {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.1
                panel.animator().alphaValue = 1
            }
        } else {
            panel.alphaValue = 1
        }

        dismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            self?.dismiss()
        }
    }

    // MARK: - Dismiss

    func dismiss() {
        dismissTask?.cancel()
        dismissTask = nil

        let shouldAnimate = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        if shouldAnimate {
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.2
                panel.animator().alphaValue = 0
            }, completionHandler: { [weak self] in
                self?.panel.orderOut(nil)
            })
        } else {
            panel.alphaValue = 0
            panel.orderOut(nil)
        }
    }
}

// MARK: - ToastContentView

/// SwiftUI view rendered inside the toast NSPanel.
private struct ToastContentView: View {
    let message: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.callout)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(.regularMaterial)
        )
    }
}

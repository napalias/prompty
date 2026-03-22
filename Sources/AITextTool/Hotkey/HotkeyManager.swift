// HotkeyManager.swift
// AITextTool
//
// CGEventTap-based global hotkey implementation.

import CoreGraphics
import Foundation

final class HotkeyManager: HotkeyManagerProtocol {
    var onHotkeyFired: (() -> Void)?
    private(set) var isRegistered: Bool = false

    func register(keyCode: CGKeyCode, modifiers: CGEventFlags) throws {
        // TODO: Implement CGEventTap registration
        isRegistered = true
    }

    func unregister() {
        // TODO: Implement CGEventTap removal
        isRegistered = false
    }

    func reregister() throws {
        // TODO: Re-register after sleep/wake
    }
}

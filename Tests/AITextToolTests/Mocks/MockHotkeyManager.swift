// MockHotkeyManager.swift
// AITextToolTests

import CoreGraphics
@testable import AITextTool

final class MockHotkeyManager: HotkeyManagerProtocol {
    var onHotkeyFired: (() -> Void)?
    private(set) var isRegistered: Bool = false

    func register(keyCode: CGKeyCode, modifiers: CGEventFlags) throws {
        isRegistered = true
    }

    func unregister() {
        isRegistered = false
    }

    func reregister() throws {
        isRegistered = true
    }

    /// Simulates a hotkey fire for testing.
    func simulateFire() {
        onHotkeyFired?()
    }
}

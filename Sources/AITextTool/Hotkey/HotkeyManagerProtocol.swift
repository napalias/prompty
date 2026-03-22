// HotkeyManagerProtocol.swift
// AITextTool

import CoreGraphics

/// Protocol for hotkey registration and callback management.
protocol HotkeyManagerProtocol: AnyObject {
    /// Callback invoked when the registered hotkey fires. Always called on main thread.
    var onHotkeyFired: (() -> Void)? { get set }
    /// Registers a global hotkey with the given key code and modifier flags.
    func register(keyCode: CGKeyCode, modifiers: CGEventFlags) throws
    /// Unregisters the current hotkey.
    func unregister()
    /// Re-registers the same hotkey (call after wake from sleep).
    func reregister() throws
    /// Whether a hotkey is currently registered.
    var isRegistered: Bool { get }
}

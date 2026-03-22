// HotkeyManagerProtocol.swift
// Prompty

import CoreGraphics

/// Protocol for hotkey registration and callback management.
/// Implementations must handle global keyboard shortcut detection via CGEventTap.
protocol HotkeyManagerProtocol: AnyObject {
    /// Callback invoked when the registered hotkey fires. Always called on main thread.
    var onHotkeyFired: (@Sendable () -> Void)? { get set }

    /// Whether a hotkey is currently registered.
    var isRegistered: Bool { get }

    /// Registers a global hotkey with the given key code and modifier flags.
    /// - Parameters:
    ///   - keyCode: The CGKeyCode to listen for (e.g. 49 for Space).
    ///   - modifiers: The modifier flags required (e.g. `.maskAlternate` for Option).
    /// - Throws: `AppError.inputMonitoringPermissionDenied` if CGEventTap creation fails.
    func register(keyCode: CGKeyCode, modifiers: CGEventFlags) throws

    /// Unregisters the current hotkey and tears down the event tap.
    func unregister()

    /// Re-registers the same hotkey after sleep/wake invalidates the event tap (19B).
    /// - Throws: `AppError.inputMonitoringPermissionDenied` if CGEventTap creation fails.
    func reregister() throws
}

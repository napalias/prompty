// MockHotkeyManager.swift
// PromptyTests

import CoreGraphics
@testable import Prompty

final class MockHotkeyManager: HotkeyManagerProtocol {

    // MARK: - Protocol Properties

    var onHotkeyFired: (@Sendable () -> Void)?
    private(set) var isRegistered: Bool = false

    // MARK: - Call Recording

    /// Number of times `register` was called.
    private(set) var registerCallCount: Int = 0

    /// The most recent key code passed to `register`.
    private(set) var lastRegisteredKeyCode: CGKeyCode?

    /// The most recent modifiers passed to `register`.
    private(set) var lastRegisteredModifiers: CGEventFlags?

    /// Number of times `unregister` was called.
    private(set) var unregisterCallCount: Int = 0

    /// Number of times `reregister` was called.
    private(set) var reregisterCallCount: Int = 0

    // MARK: - Stubbing

    /// When set, `register` throws this error instead of succeeding.
    var registerError: Error?

    // MARK: - Protocol Methods

    func register(keyCode: CGKeyCode, modifiers: CGEventFlags) throws {
        registerCallCount += 1
        lastRegisteredKeyCode = keyCode
        lastRegisteredModifiers = modifiers

        if let error = registerError {
            throw error
        }

        isRegistered = true
    }

    func unregister() {
        unregisterCallCount += 1
        isRegistered = false
    }

    func reregister() throws {
        reregisterCallCount += 1

        if let error = registerError {
            throw error
        }

        isRegistered = true
    }

    // MARK: - Simulation

    /// Simulates a hotkey fire for testing.
    func simulateFire() {
        onHotkeyFired?()
    }
}

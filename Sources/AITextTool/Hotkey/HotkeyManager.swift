// HotkeyManager.swift
// AITextTool
//
// CGEventTap-based global hotkey implementation.
// Requires Input Monitoring permission in System Settings.

import CoreGraphics
import Foundation

final class HotkeyManager: HotkeyManagerProtocol {

    // MARK: - Public Properties

    var onHotkeyFired: (@Sendable () -> Void)?
    private(set) var isRegistered: Bool = false

    // MARK: - Private State

    /// The registered key code to match against incoming keyDown events.
    private var registeredKeyCode: CGKeyCode?

    /// The registered modifier flags to match (masked to relevant bits).
    private var registeredModifiers: CGEventFlags?

    /// The Mach port backing the CGEventTap.
    private var eventTapPort: CFMachPort?

    /// The run loop source attached to the current run loop for event delivery.
    private var runLoopSource: CFRunLoopSource?

    // MARK: - Modifier Mask

    /// Only compare modifier keys the user cares about, ignoring caps lock and other device flags.
    private static let relevantModifierMask: CGEventFlags = [
        .maskShift, .maskControl, .maskAlternate, .maskCommand
    ]

    // MARK: - Registration

    func register(keyCode: CGKeyCode, modifiers: CGEventFlags) throws {
        // Tear down any existing tap before creating a new one
        unregister()

        registeredKeyCode = keyCode
        registeredModifiers = modifiers.intersection(Self.relevantModifierMask)

        // Store self in an unmanaged pointer so the C callback can reach us
        let unmanagedSelf = Unmanaged.passRetained(self)

        let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
            callback: HotkeyManager.eventTapCallback,
            userInfo: unmanagedSelf.toOpaque()
        )

        guard let eventTap else {
            unmanagedSelf.release()
            registeredKeyCode = nil
            registeredModifiers = nil
            throw AppError.inputMonitoringPermissionDenied
        }

        eventTapPort = eventTap

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        isRegistered = true
    }

    func unregister() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            runLoopSource = nil
        }

        if let port = eventTapPort {
            // Release the retained self that was passed as userInfo to the tap
            var context = CFMachPortContext()
            CFMachPortGetContext(port, &context)
            if let info = context.info {
                Unmanaged<HotkeyManager>.fromOpaque(info).release()
            }
            CFMachPortInvalidate(port)
            eventTapPort = nil
        }

        isRegistered = false
    }

    func reregister() throws {
        guard let keyCode = registeredKeyCode,
              let modifiers = registeredModifiers else {
            return
        }
        // Tear down stale tap and create a fresh one with the same key combo
        try register(keyCode: keyCode, modifiers: modifiers)
    }

    deinit {
        unregister()
    }

    // MARK: - CGEventTap Callback

    /// C-compatible callback invoked by the event tap on the run loop thread.
    /// Checks if the event matches the registered hotkey and dispatches the handler on main.
    private static let eventTapCallback: CGEventTapCallBack = {
        _, type, event, userInfo -> Unmanaged<CGEvent>? in

        // The system sends a tap-disabled notification when the tap times out;
        // re-enable it so we keep receiving events.
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let userInfo {
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userInfo)
                    .takeUnretainedValue()
                if let port = manager.eventTapPort {
                    CGEvent.tapEnable(tap: port, enable: true)
                }
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown, let userInfo else {
            return Unmanaged.passUnretained(event)
        }

        let manager = Unmanaged<HotkeyManager>.fromOpaque(userInfo)
            .takeUnretainedValue()

        let eventKeyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let eventModifiers = event.flags.intersection(relevantModifierMask)

        guard eventKeyCode == manager.registeredKeyCode,
              eventModifiers == manager.registeredModifiers else {
            return Unmanaged.passUnretained(event)
        }

        // Dispatch handler on main thread as required by the spec
        if let handler = manager.onHotkeyFired {
            DispatchQueue.main.async {
                handler()
            }
        }

        // Consume the event so it does not propagate to the frontmost app
        return nil
    }
}

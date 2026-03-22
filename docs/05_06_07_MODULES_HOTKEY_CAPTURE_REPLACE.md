# 05 — Module: HotkeyManager

## Responsibility
Register a configurable global keyboard shortcut that fires even when
AITextTool is not the frontmost app.

## Implementation

### Protocol
```swift
protocol HotkeyManagerProtocol: AnyObject {
    var onHotkeyFired: (() -> Void)? { get set }
    func register(keyCode: CGKeyCode, modifiers: CGEventFlags) throws
    func unregister()
    var isRegistered: Bool { get }
}
```

### Concrete Implementation: CGEventTap
Use `CGEvent.tapCreate` with `.cgSessionEventTap` and `.headInsertEventTap`.
The callback checks key + modifier match, consumes the event (returns nil), and
calls `onHotkeyFired`.

Required entitlement: **Input Monitoring** permission.
Request permission at first launch alongside Accessibility permission.

### Default Hotkey
`⌥Space` (Option + Space, keyCode: 49, modifiers: `.maskAlternate`)

### Error Cases
- `CGEvent.tapCreate` returns nil → throw `AppError.inputMonitoringPermissionDenied`

### Thread Safety
`onHotkeyFired` is always called on `DispatchQueue.main`.

---

# 06 — Module: TextCaptureService

## Responsibility
Read the currently selected text from whichever app is frontmost,
using AX API first and clipboard fallback for apps that block AX.

## Protocol
```swift
protocol TextCaptureServiceProtocol: AnyObject {
    func capture() async throws -> String
    var isAccessibilityGranted: Bool { get }
}
```

## Implementation Order

```
TextCaptureService.capture()
    1. Check AXIsProcessTrusted — if false, throw .accessibilityPermissionDenied
    2. Try AccessibilityReader.readSelectedText()
       - Success + non-empty → return text
       - Empty string → fall through to step 3
       - Failure (AX not supported by app) → fall through to step 3
    3. Try ClipboardFallbackReader.readSelectedText()
       - Saves clipboard, simulates ⌘C, waits 80ms, reads clipboard, restores
       - Returns text or throws .noTextSelected if clipboard didn't change
```

## AccessibilityReader

```swift
final class AccessibilityReader {
    func readSelectedText() throws -> String? {
        let system = AXUIElementCreateSystemWide()
        var focused: CFTypeRef?
        guard AXUIElementCopyAttributeValue(system,
            kAXFocusedUIElementAttribute as CFString, &focused) == .success
        else { return nil }

        var text: CFTypeRef?
        guard AXUIElementCopyAttributeValue(focused as! AXUIElement,
            kAXSelectedTextAttribute as CFString, &text) == .success
        else { return nil }

        return (text as? String).flatMap { $0.isEmpty ? nil : $0 }
    }
}
```

## ClipboardFallbackReader

```swift
final class ClipboardFallbackReader {
    private let waitDuration: Duration  // injected, default .milliseconds(80)

    func readSelectedText() async throws -> String {
        let pasteboard = NSPasteboard.general
        // 1. Save existing contents
        let savedChangeCount = pasteboard.changeCount
        let savedContents = pasteboard.pasteboardItems?
            .compactMap { $0.data(forType: .string) }

        // 2. Simulate ⌘C
        simulateCopyKeystroke()

        // 3. Wait
        try await Task.sleep(for: waitDuration)

        // 4. Read if clipboard changed
        guard pasteboard.changeCount != savedChangeCount else {
            throw AppError.noTextSelected
        }
        let text = pasteboard.string(forType: .string) ?? ""

        // 5. Restore clipboard
        restoreClipboard(savedContents)

        guard !text.isEmpty else { throw AppError.noTextSelected }
        return text
    }
}
```

## PermissionChecker
```swift
final class PermissionChecker {
    func requestAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    func requestInputMonitoringIfNeeded() {
        // IOHIDCheckAccess / prompt pattern
    }
}
```

---

# 07 — Module: TextReplaceService

## Responsibility
Write a new string back into the source app, replacing the previously selected text.

## Protocol
```swift
protocol TextReplaceServiceProtocol: AnyObject {
    func replace(with text: String) async throws
    func copyToClipboard(_ text: String)
}
```

## Implementation Order
```
TextReplaceService.replace(with:)
    1. Try AccessibilityWriter.writeSelectedText(text)
       - Uses kAXSelectedTextAttribute setter
       - Success → return
    2. Fall back to ClipboardPasteWriter.paste(text)
       - Sets clipboard to text
       - Simulates ⌘V
       - Restores original clipboard after 500ms delay
```

## AccessibilityWriter
```swift
final class AccessibilityWriter {
    func writeSelectedText(_ text: String) throws {
        let system = AXUIElementCreateSystemWide()
        var focused: CFTypeRef?
        guard AXUIElementCopyAttributeValue(system,
            kAXFocusedUIElementAttribute as CFString, &focused) == .success
        else { throw AppError.cannotReplaceInApp(appName: "Unknown") }

        let result = AXUIElementSetAttributeValue(
            focused as! AXUIElement,
            kAXSelectedTextAttribute as CFString,
            text as CFTypeRef
        )
        guard result == .success else {
            throw AppError.cannotReplaceInApp(appName: frontmostAppName())
        }
    }
}
```

## Important Notes
- After `TextReplaceService.replace()` succeeds, call `FloatingPanelController.hide()`
- `copyToClipboard` is always synchronous and never throws
- The 500ms clipboard restore delay in paste writer must be cancellable
  (use `Task` stored in a property, cancel on panel dismiss)

# 16 — Edge Cases

---

## 16A — Cancel In-Flight AI Request

### Problem
When streaming is active, the user must be able to press Escape to cancel immediately.
Without explicit cancellation, the `Task` running the stream keeps consuming network
and the sidecar keeps processing even after the panel is dismissed.

### Spec

#### AppState addition
```swift
// AppState.swift — add this property
private(set) var streamingTask: Task<Void, Never>? = nil

func startStreaming(task: Task<Void, Never>) {
    streamingTask = task
}

func cancelStreaming() {
    streamingTask?.cancel()
    streamingTask = nil
    isStreaming = false
}
```

#### Where streaming is started (FloatingPanelController or a StreamingCoordinator)
```swift
// Always store the Task so it can be cancelled
let task = Task { @MainActor in
    do {
        for try await token in aiManager.stream(request: request) {
            // Check for cancellation before each token
            try Task.checkCancellation()
            state.streamingTokens += token
        }
        state.isStreaming = false
    } catch is CancellationError {
        // Clean cancellation — do nothing, panel handles UI
        state.isStreaming = false
    } catch {
        state.streamingError = error as? AppError ?? .streamInterrupted
        state.panelMode = .error
    }
}
state.startStreaming(task: task)
```

#### Escape key handler in MainPanelView
```swift
.onKeyPress(.escape) {
    if state.isStreaming {
        // Mid-stream: cancel and show partial result
        state.cancelStreaming()
        // Keep streamingTokens visible — user sees partial result
        // Show action bar so they can still copy/replace partial text
        return .handled
    } else {
        // Not streaming: dismiss panel entirely
        panelController.hide()
        return .handled
    }
}
```

#### StreamingResultView — cancel button
Show a "Stop" button alongside the streaming indicator (in addition to Escape):
```swift
if state.isStreaming {
    Button("Stop") { state.cancelStreaming() }
        .keyboardShortcut(.escape, modifiers: [])
}
```

#### Every AIProvider must support cancellation
Each provider's `stream()` implementation must check `Task.isCancelled` in its loop:
```swift
// Inside AsyncThrowingStream continuation
for line in lines {
    if Task.isCancelled {
        continuation.finish()
        return
    }
    // ... process line
}
```

#### OAuthSidecar cancellation
Send a cancel message to the sidecar:
```json
{ "type": "cancel", "requestId": "uuid" }
```
Sidecar must handle this and stop the in-progress query.

---

## 16B — Secure Input Field Detection

### Problem
When a password field is active anywhere on the system (1Password, Safari login,
Terminal sudo prompt, etc.), macOS activates "Secure Input Mode". In this mode:
- All `CGEventTap` monitoring is blocked system-wide
- The AX API cannot read text from the focused element
- `NSPasteboard` clipboard simulation may also be blocked

Attempting to capture text silently fails or returns empty string, confusing the user.

### Spec

#### SecureInputDetector
```swift
// SecureInputDetector.swift
import Carbon

struct SecureInputDetector {
    /// Returns true if any app has activated secure keyboard input.
    /// Uses the undocumented but stable Carbon function IsSecureEventInputEnabled().
    static var isActive: Bool {
        return IsSecureEventInputEnabled()
    }
}
```

#### Where to call it
In `TextCaptureService.capture()`, check BEFORE attempting AX or clipboard:
```swift
func capture() async throws -> String {
    guard !SecureInputDetector.isActive else {
        throw AppError.secureInputActive
    }
    // ... rest of capture logic
}
```

#### New AppError case
```swift
case secureInputActive
// errorDescription: "Cannot read text in a secure input field"
// recoverySuggestion: "Click away from the password field first, then try again"
```

#### UI treatment in ErrorView
Show a lock icon (SF Symbol: `lock.fill`) and the message above.
Do NOT show a retry button — user must resolve the condition themselves.

#### Hotkey behaviour
When secure input is active, the hotkey still fires (the EventTap cannot be blocked
from receiving the keydown, only from intercepting it at the session tap level).
The panel opens, capture is attempted, SecureInputDetector fires, ErrorView shows.
This is acceptable — do not attempt to suppress the hotkey itself.

---

## 16C — Long Text Handling

### Problem
If a user selects an entire document or article, the captured text may exceed
provider context windows, cause API errors, or produce very high token costs.

### Defined Limits

| Limit | Value | Reason |
|-------|-------|--------|
| Soft warning | 4,000 chars | Show yellow indicator |
| Hard cap | 12,000 chars | Truncate with ellipsis + show warning |
| Truncation strategy | Keep first + last 20% | Preserves context and conclusion |

4,000 chars ≈ ~1,000 tokens — practical for most prompts.
12,000 chars ≈ ~3,000 tokens — within all provider limits.

#### TextCaptureService addition
```swift
extension TextCaptureService {
    static let softLimit = 4_000
    static let hardLimit = 12_000

    func truncateIfNeeded(_ text: String) -> (text: String, wasTruncated: Bool) {
        guard text.count > hardLimit else {
            return (text, false)
        }
        let keepEach = hardLimit / 5        // 20% from each end = 40% total
        let head = text.prefix(keepEach * 2)
        let tail = text.suffix(keepEach)
        let truncated = "\(head)\n\n[... \(text.count - hardLimit) characters omitted ...]\n\n\(tail)"
        return (truncated, true)
    }
}
```

#### AppState addition
```swift
var capturedTextWasTruncated: Bool = false
var capturedTextOriginalLength: Int = 0
```

#### PromptPickerView — warning banner
```swift
if state.capturedTextOriginalLength > TextCaptureService.hardLimit {
    Label("Text was truncated to \(TextCaptureService.hardLimit) chars",
          systemImage: "scissors")
        .foregroundStyle(.orange)
        .font(.caption)
} else if state.capturedTextOriginalLength > TextCaptureService.softLimit {
    Label("\(state.capturedTextOriginalLength) chars selected",
          systemImage: "exclamationmark.triangle")
        .foregroundStyle(.yellow)
        .font(.caption)
}
```

#### New AppError case (for future use)
```swift
case textTooLong(charCount: Int, limit: Int)
```

---

## 16D — Multi-Monitor Panel Positioning

### Problem
If the mouse cursor is near the right or bottom edge of any screen (including
non-primary displays), the floating panel may render partially or fully off-screen.

### Spec

#### FloatingPanelController.show(near:) — complete positioning algorithm

```swift
func show(near cursorPoint: NSPoint) {
    let panelSize = panel.frame.size  // 480 × (dynamic height)
    let padding: CGFloat = 12         // minimum distance from screen edge

    // 1. Find the screen containing the cursor
    let screen = NSScreen.screens.first(where: { NSMouseInRect(cursorPoint, $0.frame, false) })
               ?? NSScreen.main
               ?? NSScreen.screens[0]

    let visibleFrame = screen.visibleFrame  // excludes menu bar and dock

    // 2. Default: appear just above and left of cursor
    var origin = NSPoint(
        x: cursorPoint.x - (panelSize.width / 2),
        y: cursorPoint.y + 20
    )

    // 3. Clamp X to screen bounds
    if origin.x + panelSize.width > visibleFrame.maxX - padding {
        origin.x = visibleFrame.maxX - panelSize.width - padding
    }
    if origin.x < visibleFrame.minX + padding {
        origin.x = visibleFrame.minX + padding
    }

    // 4. Clamp Y: if panel would go above top of screen, flip below cursor
    if origin.y + panelSize.height > visibleFrame.maxY - padding {
        origin.y = cursorPoint.y - panelSize.height - 20
    }

    // 5. Final Y clamp (in case below-cursor is also off screen — rare)
    if origin.y < visibleFrame.minY + padding {
        origin.y = visibleFrame.minY + padding
    }

    panel.setFrameOrigin(origin)
    panel.makeKeyAndOrderFront(nil)
}
```

#### Dynamic height consideration
The panel height is not fixed — it grows with the streaming result.
After height changes (e.g. result arrives), re-run the Y clamp:
```swift
// In StreamingResultView, when content overflows
.onChange(of: state.streamingTokens) { _ in
    panelController.repositionIfNeeded()
}
```

`repositionIfNeeded()` re-runs the clamp with the new panel height,
only adjusting Y — never jumping the panel's X position mid-session.

#### Tests
```
test_positioning_cursorNearRightEdge_clampsToScreenRight
test_positioning_cursorNearTopEdge_flipsBelow
test_positioning_cursorOnSecondaryMonitor_usesCorrectScreenBounds
test_positioning_verySmallScreen_stillFullyVisible
```

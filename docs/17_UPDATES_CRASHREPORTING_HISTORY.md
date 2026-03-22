# 17 — Updates, Crash Reporting & History

---

## 17A — Auto-Update (Sparkle)

### Why Sparkle
Sparkle is the standard macOS non-App-Store update framework. It checks a hosted
appcast XML file, compares version numbers, downloads and installs deltas, and
handles the full update UX natively. It is open source and widely trusted.

### Package
```swift
// Package.swift or via Xcode SPM UI
.package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0")
```

### Appcast File
Host at a stable URL. Recommended: GitHub Pages or a private Gist.
Format: `https://your-username.github.io/AITextTool/appcast.xml`

```xml
<!-- appcast.xml — update this file with every release -->
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>AITextTool</title>
    <item>
      <title>Version 0.2.0</title>
      <sparkle:version>20</sparkle:version>           <!-- build number -->
      <sparkle:shortVersionString>0.2.0</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>15.0</sparkle:minimumSystemVersion>
      <pubDate>Mon, 01 Jan 2026 12:00:00 +0000</pubDate>
      <enclosure
        url="https://github.com/.../releases/download/v0.2.0/AITextTool-0.2.0.dmg"
        sparkle:edSignature="<ED25519 SIGNATURE>"
        length="12345678"
        type="application/octet-stream"/>
      <sparkle:releaseNotesLink>
        https://your-username.github.io/AITextTool/release-notes/0.2.0.html
      </sparkle:releaseNotesLink>
    </item>
  </channel>
</rss>
```

### Info.plist Keys
```xml
<key>SUFeedURL</key>
<string>https://your-username.github.io/AITextTool/appcast.xml</string>

<key>SUPublicEDKey</key>
<string><!-- paste public key from generate_keys tool --></string>

<key>SUEnableAutomaticChecks</key>
<true/>

<key>SUAutomaticallyUpdate</key>
<false/>  <!-- prompt user, don't silently install -->
```

### AppDelegate Integration
```swift
// AppDelegate.swift
import Sparkle

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var updaterController: SPUStandardUpdaterController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }
}
```

### MenuBarController — Check for Updates menu item
```swift
// MenuBarController.swift
NSMenuItem(
    title: "Check for Updates…",
    action: #selector(checkForUpdates),
    keyEquivalent: ""
)

@objc func checkForUpdates() {
    updaterController.checkForUpdates(nil)
}
```

### Key Generation (run once, keep private key secret)
```bash
# Sparkle includes this tool
./bin/generate_keys
# Outputs: public key (put in Info.plist), private key (keep safe — never commit)

# Sign a release DMG
./bin/sign_update AITextTool-0.2.0.dmg  # uses private key from keychain
```

### CI Release Workflow Addition
Add to `.github/workflows/release.yml`:
```yaml
- name: Sign DMG for Sparkle
  env:
    SPARKLE_PRIVATE_KEY: ${{ secrets.SPARKLE_PRIVATE_KEY }}
  run: |
    echo "$SPARKLE_PRIVATE_KEY" > sparkle_private.pem
    ./Sparkle.framework/Resources/sign_update \
      AITextTool-${{ github.ref_name }}.dmg > sparkle_sig.txt
    # Embed signature in appcast.xml update step
```

---

## 17B — Crash Reporting (Local Only, No Telemetry)

### Policy
**Zero data leaves the device.** No Sentry, no Crashlytics, no Firebase.
All crash information is written to local log files only.
The user can view logs in the Settings window and delete them at any time.

### Implementation

#### CrashReporter.swift
```swift
// CrashReporter.swift
import Foundation
import os

final class CrashReporter {
    static let shared = CrashReporter()

    private let logDirectory: URL = {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("AITextTool/Logs")
    }()

    private init() {
        try? FileManager.default.createDirectory(
            at: logDirectory, withIntermediateDirectories: true)
        installSignalHandlers()
        registerUncaughtExceptionHandler()
    }

    // MARK: - Signal Handlers (catches SIGABRT, SIGSEGV, SIGBUS, etc.)
    private func installSignalHandlers() {
        let signals = [SIGABRT, SIGSEGV, SIGBUS, SIGILL, SIGTRAP]
        signals.forEach { sig in
            signal(sig) { signalNumber in
                CrashReporter.shared.writeCrashLog(
                    reason: "Signal \(signalNumber)",
                    callStack: Thread.callStackSymbols
                )
                // Re-raise to allow default crash handler to run
                signal(signalNumber, SIG_DFL)
                raise(signalNumber)
            }
        }
    }

    // MARK: - Uncaught Swift exceptions
    private func registerUncaughtExceptionHandler() {
        NSSetUncaughtExceptionHandler { exception in
            CrashReporter.shared.writeCrashLog(
                reason: exception.reason ?? "Unknown exception: \(exception.name.rawValue)",
                callStack: exception.callStackSymbols
            )
        }
    }

    // MARK: - Write log
    func writeCrashLog(reason: String, callStack: [String]) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString

        var log = """
        AITextTool Crash Report
        =======================
        Date:        \(timestamp)
        App Version: \(appVersion) (\(buildNumber))
        macOS:       \(osVersion)
        Reason:      \(reason)

        Call Stack:
        \(callStack.joined(separator: "\n"))

        """

        let filename = "crash_\(timestamp.replacingOccurrences(of: ":", with: "-")).log"
        let fileURL = logDirectory.appendingPathComponent(filename)
        try? log.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    // MARK: - Log structured errors (non-fatal)
    func logError(_ error: AppError, context: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let entry = "[\(timestamp)] ERROR [\(context)]: \(error.localizedDescription)\n"
        let fileURL = logDirectory.appendingPathComponent("errors.log")

        if let handle = try? FileHandle(forWritingTo: fileURL) {
            handle.seekToEndOfFile()
            handle.write(entry.data(using: .utf8)!)
            handle.closeFile()
        } else {
            try? entry.write(to: fileURL, atomically: false, encoding: .utf8)
        }
        rotateLogsIfNeeded()
    }

    // MARK: - Log rotation (keep last 7 days / 5MB max)
    private func rotateLogsIfNeeded() {
        let maxSize: Int = 5 * 1024 * 1024  // 5MB
        let maxAge: TimeInterval = 7 * 24 * 3600  // 7 days
        let errorLog = logDirectory.appendingPathComponent("errors.log")

        if let size = try? errorLog.resourceValues(forKeys: [.fileSizeKey]).fileSize,
           size > maxSize {
            let archive = logDirectory.appendingPathComponent(
                "errors_\(Int(Date().timeIntervalSince1970)).log")
            try? FileManager.default.moveItem(at: errorLog, to: archive)
        }

        // Delete crash logs older than maxAge
        let crashLogs = (try? FileManager.default.contentsOfDirectory(
            at: logDirectory, includingPropertiesForKeys: [.creationDateKey])) ?? []
        let cutoff = Date().addingTimeInterval(-maxAge)
        for url in crashLogs where url.lastPathComponent.hasPrefix("crash_") {
            let created = (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date()
            if created < cutoff { try? FileManager.default.removeItem(at: url) }
        }
    }

    // MARK: - Settings UI support
    var allLogFiles: [URL] {
        (try? FileManager.default.contentsOfDirectory(
            at: logDirectory,
            includingPropertiesForKeys: [.creationDateKey, .fileSizeKey]))?
            .sorted { a, b in
                let aDate = (try? a.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let bDate = (try? b.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return aDate > bDate
            } ?? []
    }

    func deleteAllLogs() throws {
        try FileManager.default.removeItem(at: logDirectory)
        try FileManager.default.createDirectory(
            at: logDirectory, withIntermediateDirectories: true)
    }
}
```

#### Settings UI — Logs Tab
Add a fourth tab to `SettingsView.swift`:

```
[General] [Providers] [Prompts] [Logs]

LOGS tab:
  ┌──────────────────────────────────────────┐
  │ Log Files  (stored locally, never sent)  │
  │                                          │
  │  errors.log          2.3 KB  2d ago  [↗] │
  │  crash_2026-03-...   4.1 KB  5d ago  [↗] │
  │                                          │
  │  [ Open Logs Folder ]  [ Delete All ]    │
  └──────────────────────────────────────────┘
```

[↗] opens the file in Console.app.
"Open Logs Folder" opens in Finder.
"Delete All" calls `CrashReporter.shared.deleteAllLogs()` with confirmation alert.

---

## 17C — Conversation History Persistence

### Design Decision
History is scoped to **sessions**. A session starts when the hotkey fires on
a piece of text and ends when the panel is dismissed. Within a session,
`continueChat` mode persists the full conversation.

Across sessions: keep the last N sessions for viewing in a History panel,
but do NOT auto-load previous context into new AI requests unless the user
explicitly taps "Resume".

### Models

```swift
// ConversationSession.swift
struct ConversationSession: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    var updatedAt: Date
    let originalText: String        // what was captured
    let providerID: String          // which AI was used
    let promptTitle: String         // which prompt was chosen
    var messages: [AIMessage]       // full back-and-forth
    var finalResult: String?        // last assistant message

    var summary: String {
        // First 80 chars of originalText, for display in history list
        String(originalText.prefix(80)).appending(originalText.count > 80 ? "…" : "")
    }
}
```

### SessionHistoryRepository

```swift
protocol SessionHistoryRepositoryProtocol {
    func save(_ session: ConversationSession) throws
    func all() -> [ConversationSession]            // newest first
    func delete(id: UUID) throws
    func deleteAll() throws
}
```

Storage:
- Location: `~/Library/Application Support/AITextTool/history/`
- One JSON file per session: `<session-id>.json`
- Retention: keep last **50 sessions** (delete oldest when exceeded)
- Max size per session: if `originalText` > 12,000 chars, truncate to 500 chars in stored session

### AppState additions
```swift
var currentSession: ConversationSession? = nil

func startSession(capturedText: String, prompt: Prompt, providerID: String) {
    currentSession = ConversationSession(
        id: UUID(),
        createdAt: Date(),
        updatedAt: Date(),
        originalText: capturedText,
        providerID: providerID,
        promptTitle: prompt.title,
        messages: [],
        finalResult: nil
    )
}

func appendToSession(message: AIMessage) {
    currentSession?.messages.append(message)
    currentSession?.updatedAt = Date()
    if message.role == .assistant {
        currentSession?.finalResult = message.content
    }
}

func endSession() {
    guard let session = currentSession else { return }
    try? sessionRepo.save(session)
    currentSession = nil
    conversationHistory = []
}
```

### History UI (Menu Bar)
Add to `MenuBarController`:
```
History         ► (submenu, last 5 sessions)
  "Fix Grammar on 'The quick bro…'"   Mar 21
  "Translate on 'Bonjour tout le…'"   Mar 20
  ─────────────
  Show All History…
  Clear History…
```

"Show All History…" opens a sheet window with the full session list.
Clicking a session shows a read-only view of the conversation.
"Resume" button on a session opens the panel in `continueChat` mode,
pre-populated with that session's history and captured text.

### Privacy Note (add to Settings → General)
```
"Conversation history is stored locally in:
 ~/Library/Application Support/AITextTool/history/
 It is never sent anywhere."
[Open Folder]  [Clear All History…]
```

### Required Tests
```
test_startSession_createsSessionWithCorrectMetadata
test_appendToSession_accumulatesMessages
test_endSession_persistsToRepository_andClearsState
test_saveSession_respectsRetentionLimit (51st session deletes oldest)
test_deleteAll_removesAllFiles
```

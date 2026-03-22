// CrashReporter.swift
// Prompty
//
// Local-only crash reporting. Zero data leaves the device.
// Writes crash logs and structured error logs to
// ~/Library/Application Support/Prompty/Logs/

import Foundation
import os

final class CrashReporter: @unchecked Sendable {
    static let shared = CrashReporter()

    private let logDirectory: URL = {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("Prompty/Logs")
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
        for sig in signals {
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

        let log = """
        Prompty Crash Report
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
            if let data = entry.data(using: .utf8) {
                handle.write(data)
            }
            handle.closeFile()
        } else {
            try? entry.write(to: fileURL, atomically: false, encoding: .utf8)
        }
        rotateLogsIfNeeded()
    }

    // MARK: - Log rotation (keep last 7 days / 5MB max)

    private func rotateLogsIfNeeded() {
        let maxSize: Int = 5 * 1_024 * 1_024 // 5MB
        let maxAge: TimeInterval = 7 * 24 * 3_600 // 7 days
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
            let created = (try? url.resourceValues(
                forKeys: [.creationDateKey]).creationDate) ?? Date()
            if created < cutoff {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    // MARK: - Settings UI support

    var allLogFiles: [URL] {
        (try? FileManager.default.contentsOfDirectory(
            at: logDirectory,
            includingPropertiesForKeys: [.creationDateKey, .fileSizeKey]))?
            .sorted { first, second in
                let aDate = (try? first.resourceValues(
                    forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let bDate = (try? second.resourceValues(
                    forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return aDate > bDate
            } ?? []
    }

    func deleteAllLogs() throws {
        try FileManager.default.removeItem(at: logDirectory)
        try FileManager.default.createDirectory(
            at: logDirectory, withIntermediateDirectories: true)
    }

    /// The directory where logs are stored, for opening in Finder.
    var logsDirectoryURL: URL { logDirectory }
}

// LogsSettingsView.swift
// AITextTool
//
// Fourth tab in Settings. Shows local log files with size and age.
// "Open Logs Folder" opens in Finder, "Delete All" with confirmation.
// Privacy note: logs are stored locally and never sent anywhere.

import SwiftUI

// MARK: - LogsSettingsView

struct LogsSettingsView: View {
    let crashReporter: CrashReporter
    @State private var logFiles: [URL] = []
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Strings.Logs.title)
                .font(.headline)

            Text(Strings.Logs.privacyNote)
                .font(.caption)
                .foregroundStyle(.secondary)

            if logFiles.isEmpty {
                Text(Strings.Settings.noLogsMessage)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                List {
                    ForEach(logFiles, id: \.absoluteString) { file in
                        LogFileRow(fileURL: file)
                    }
                }
                .listStyle(.bordered)
                .frame(minHeight: 180)
            }

            HStack {
                Button(Strings.Logs.openFolder) {
                    NSWorkspace.shared.open(crashReporter.logsDirectoryURL)
                }

                Spacer()

                Button(Strings.Logs.deleteAll, role: .destructive) {
                    showDeleteConfirmation = true
                }
                .disabled(logFiles.isEmpty)
            }
        }
        .padding()
        .alert(Strings.Logs.deleteConfirmTitle, isPresented: $showDeleteConfirmation) {
            Button(Strings.Logs.deleteAll, role: .destructive) {
                try? crashReporter.deleteAllLogs()
                logFiles = crashReporter.allLogFiles
            }
            Button(Strings.Logs.cancel, role: .cancel) {}
        } message: {
            Text(Strings.Logs.deleteConfirmMessage)
        }
        .onAppear {
            logFiles = crashReporter.allLogFiles
        }
    }
}

// MARK: - LogFileRow

private struct LogFileRow: View {
    let fileURL: URL

    var body: some View {
        HStack {
            Text(fileURL.lastPathComponent)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Text(fileSizeString)
                .foregroundStyle(.secondary)
                .font(.caption)

            Text(fileAgeString)
                .foregroundStyle(.secondary)
                .font(.caption)
                .frame(width: 60, alignment: .trailing)

            Button {
                NSWorkspace.shared.open(fileURL)
            } label: {
                Image(systemName: "arrow.up.right.square")
            }
            .buttonStyle(.borderless)
            .help(Strings.Logs.openInConsole)
        }
    }

    private var fileSizeString: String {
        guard let size = try? fileURL.resourceValues(
            forKeys: [.fileSizeKey]).fileSize else {
            return ""
        }
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    private var fileAgeString: String {
        guard let created = try? fileURL.resourceValues(
            forKeys: [.creationDateKey]).creationDate else {
            return ""
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: created, relativeTo: Date())
    }
}

#Preview {
    LogsSettingsView(crashReporter: .shared)
        .frame(width: 500, height: 400)
}

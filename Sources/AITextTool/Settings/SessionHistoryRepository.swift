// SessionHistoryRepository.swift
// AITextTool
//
// JSON file-based persistence for conversation sessions.
// One JSON file per session in ~/Library/Application Support/AITextTool/history/.

import Foundation
import os

// MARK: - Protocol

protocol SessionHistoryRepositoryProtocol: Sendable {
    func save(_ session: ConversationSession) throws
    func all() -> [ConversationSession]
    func delete(id: UUID) throws
    func deleteAll() throws
}

// MARK: - Implementation

final class SessionHistoryRepository: SessionHistoryRepositoryProtocol, Sendable {

    // MARK: - Constants

    private static let maxSessions = 50
    private static let maxOriginalTextLength = 12_000
    private static let truncatedTextLength = 500

    // MARK: - Properties

    private let directory: URL

    // MARK: - Init

    init(directory: URL? = nil) {
        if let directory {
            self.directory = directory
        } else {
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )[0]
            self.directory = appSupport
                .appendingPathComponent("AITextTool")
                .appendingPathComponent("history")
        }
        try? FileManager.default.createDirectory(
            at: self.directory,
            withIntermediateDirectories: true
        )
    }

    // MARK: - SessionHistoryRepositoryProtocol

    func save(_ session: ConversationSession) throws {
        var sessionToStore = session
        if sessionToStore.originalText.count > Self.maxOriginalTextLength {
            sessionToStore = ConversationSession(
                id: session.id,
                createdAt: session.createdAt,
                updatedAt: session.updatedAt,
                originalText: String(session.originalText.prefix(Self.truncatedTextLength)),
                providerID: session.providerID,
                promptTitle: session.promptTitle,
                messages: session.messages,
                finalResult: session.finalResult
            )
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(sessionToStore)

        let fileURL = fileURL(for: session.id)
        try data.write(to: fileURL, options: .atomic)

        Logger.history.info("Saved session \(session.id.uuidString, privacy: .public)")

        enforceRetentionLimit()
    }

    func all() -> [ConversationSession] {
        let fileManager = FileManager.default
        guard let contents = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let sessions: [ConversationSession] = contents
            .filter { $0.pathExtension == "json" }
            .compactMap { url in
                guard let data = try? Data(contentsOf: url),
                      let session = try? decoder.decode(ConversationSession.self, from: data) else {
                    Logger.history.warning(
                        "Failed to decode session file: \(url.lastPathComponent, privacy: .public)"
                    )
                    return nil
                }
                return session
            }
            .sorted { $0.createdAt > $1.createdAt }

        return sessions
    }

    func delete(id: UUID) throws {
        let url = fileURL(for: id)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
        Logger.history.info("Deleted session \(id.uuidString, privacy: .public)")
    }

    func deleteAll() throws {
        let fileManager = FileManager.default
        try fileManager.removeItem(at: directory)
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        Logger.history.info("Deleted all session history")
    }

    // MARK: - Private

    private func fileURL(for id: UUID) -> URL {
        directory.appendingPathComponent("\(id.uuidString).json")
    }

    private func enforceRetentionLimit() {
        let sessions = all()
        guard sessions.count > Self.maxSessions else { return }

        let toDelete = sessions.suffix(from: Self.maxSessions)
        for session in toDelete {
            try? delete(id: session.id)
        }

        Logger.history.info(
            "Enforced retention limit, deleted \(toDelete.count, privacy: .public) oldest sessions"
        )
    }
}

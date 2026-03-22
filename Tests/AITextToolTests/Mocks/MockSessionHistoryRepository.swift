// MockSessionHistoryRepository.swift
// AITextToolTests

import Foundation
@testable import AITextTool

final class MockSessionHistoryRepository: SessionHistoryRepositoryProtocol, @unchecked Sendable {

    private(set) var sessions: [ConversationSession] = []
    private(set) var saveCallCount = 0
    private(set) var deleteAllCallCount = 0

    func save(_ session: ConversationSession) throws {
        saveCallCount += 1
        sessions.removeAll { $0.id == session.id }
        sessions.append(session)
    }

    func all() -> [ConversationSession] {
        sessions.sorted { $0.createdAt > $1.createdAt }
    }

    func delete(id: UUID) throws {
        sessions.removeAll { $0.id == id }
    }

    func deleteAll() throws {
        deleteAllCallCount += 1
        sessions.removeAll()
    }
}

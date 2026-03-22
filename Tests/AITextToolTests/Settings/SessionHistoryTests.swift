// SessionHistoryTests.swift
// AITextToolTests

import Foundation
import Testing
@testable import AITextTool

// MARK: - AppState Session Lifecycle Tests

@MainActor
@Suite("AppState Session Lifecycle")
struct AppStateSessionLifecycleTests {

    private func makePrompt(title: String = "Fix Grammar") -> Prompt {
        Prompt(
            id: UUID(),
            title: title,
            icon: "wand.and.stars",
            template: "Fix grammar: {{text}}",
            resultMode: .replace
        )
    }

    @Test
    func test_startSession_createsSessionWithCorrectMetadata() {
        let mockRepo = MockSessionHistoryRepository()
        let state = AppState(sessionRepo: mockRepo)
        let prompt = makePrompt(title: "Translate")

        state.startSession(
            capturedText: "Hello world",
            prompt: prompt,
            providerID: "anthropic-api"
        )

        let session = state.currentSession
        #expect(session != nil)
        #expect(session?.originalText == "Hello world")
        #expect(session?.promptTitle == "Translate")
        #expect(session?.providerID == "anthropic-api")
        #expect(session?.messages.isEmpty == true)
        #expect(session?.finalResult == nil)
    }

    @Test
    func test_appendToSession_accumulatesMessages() {
        let mockRepo = MockSessionHistoryRepository()
        let state = AppState(sessionRepo: mockRepo)
        let prompt = makePrompt()

        state.startSession(
            capturedText: "Test text",
            prompt: prompt,
            providerID: "openai"
        )

        let userMessage = AIMessage(role: .user, content: "Fix this")
        state.appendToSession(message: userMessage)

        #expect(state.currentSession?.messages.count == 1)
        #expect(state.currentSession?.messages.first?.role == .user)

        let assistantMessage = AIMessage(role: .assistant, content: "Fixed text")
        state.appendToSession(message: assistantMessage)

        #expect(state.currentSession?.messages.count == 2)
        #expect(state.currentSession?.finalResult == "Fixed text")
    }

    @Test
    func test_endSession_persistsToRepository_andClearsState() {
        let mockRepo = MockSessionHistoryRepository()
        let state = AppState(sessionRepo: mockRepo)
        let prompt = makePrompt()

        state.startSession(
            capturedText: "Some text",
            prompt: prompt,
            providerID: "anthropic-api"
        )

        let message = AIMessage(role: .assistant, content: "Result")
        state.appendToSession(message: message)

        state.endSession()

        #expect(state.currentSession == nil)
        #expect(state.conversationHistory.isEmpty)
        #expect(mockRepo.saveCallCount == 1)
        #expect(mockRepo.sessions.count == 1)
        #expect(mockRepo.sessions.first?.originalText == "Some text")
    }
}

// MARK: - SessionHistoryRepository Tests

@Suite("SessionHistoryRepository")
struct SessionHistoryRepositoryTests {

    private func makeTempDirectory() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("AITextToolTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: tempDir,
            withIntermediateDirectories: true
        )
        return tempDir
    }

    private func makeSession(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        originalText: String = "Hello world",
        promptTitle: String = "Fix Grammar"
    ) -> ConversationSession {
        ConversationSession(
            id: id,
            createdAt: createdAt,
            updatedAt: createdAt,
            originalText: originalText,
            providerID: "anthropic-api",
            promptTitle: promptTitle,
            messages: [
                AIMessage(role: .user, content: "Fix this"),
                AIMessage(role: .assistant, content: "Fixed")
            ],
            finalResult: "Fixed"
        )
    }

    @Test
    func test_saveSession_respectsRetentionLimit() throws {
        let tempDir = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let repo = SessionHistoryRepository(directory: tempDir)

        for index in 0..<51 {
            let date = Date(timeIntervalSince1970: Double(index) * 60)
            let session = makeSession(createdAt: date)
            try repo.save(session)
        }

        let allSessions = repo.all()
        #expect(allSessions.count <= 50)
    }

    @Test
    func test_deleteAll_removesAllFiles() throws {
        let tempDir = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let repo = SessionHistoryRepository(directory: tempDir)

        for _ in 0..<5 {
            let session = makeSession()
            try repo.save(session)
        }

        #expect(repo.all().count == 5)

        try repo.deleteAll()

        #expect(repo.all().isEmpty)
    }

    @Test
    func test_save_truncatesLongOriginalText() throws {
        let tempDir = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let repo = SessionHistoryRepository(directory: tempDir)

        let longText = String(repeating: "a", count: 15_000)
        let session = makeSession(originalText: longText)
        try repo.save(session)

        let loaded = repo.all()
        #expect(loaded.count == 1)
        #expect(loaded.first?.originalText.count == 500)
    }

    @Test
    func test_save_andReload_roundTrip() throws {
        let tempDir = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let repo = SessionHistoryRepository(directory: tempDir)

        let sessionID = UUID()
        let session = makeSession(
            id: sessionID,
            originalText: "Round trip test",
            promptTitle: "Translate"
        )
        try repo.save(session)

        let loaded = repo.all()
        #expect(loaded.count == 1)
        #expect(loaded.first?.id == sessionID)
        #expect(loaded.first?.originalText == "Round trip test")
        #expect(loaded.first?.promptTitle == "Translate")
    }

    @Test
    func test_delete_removesSingleSession() throws {
        let tempDir = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let repo = SessionHistoryRepository(directory: tempDir)

        let id1 = UUID()
        let id2 = UUID()
        try repo.save(makeSession(id: id1))
        try repo.save(makeSession(id: id2))

        #expect(repo.all().count == 2)

        try repo.delete(id: id1)

        let remaining = repo.all()
        #expect(remaining.count == 1)
        #expect(remaining.first?.id == id2)
    }

    @Test
    func test_all_returnsNewestFirst() throws {
        let tempDir = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let repo = SessionHistoryRepository(directory: tempDir)

        let older = makeSession(
            createdAt: Date(timeIntervalSince1970: 1000),
            promptTitle: "Older"
        )
        let newer = makeSession(
            createdAt: Date(timeIntervalSince1970: 2000),
            promptTitle: "Newer"
        )

        try repo.save(older)
        try repo.save(newer)

        let results = repo.all()
        #expect(results.first?.promptTitle == "Newer")
        #expect(results.last?.promptTitle == "Older")
    }
}

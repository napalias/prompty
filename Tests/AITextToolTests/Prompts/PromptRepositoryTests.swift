// PromptRepositoryTests.swift
// AITextToolTests
//
// Tests for PromptRepository -- JSON file-based prompt persistence.
// Uses MockFileManager to avoid real filesystem I/O.

import XCTest
@testable import AITextTool

// MARK: - MockFileManager for testing

final class MockFileManager: FileManagerProtocol, @unchecked Sendable {
    var files: [String: Data] = [:]
    var directories: Set<String> = []
    var writeError: Error?

    func fileExists(atPath path: String) -> Bool {
        files[path] != nil || directories.contains(path)
    }

    func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool
    ) throws {
        directories.insert(url.path)
    }

    func contentsOfFile(at url: URL) throws -> Data {
        guard let data = files[url.path] else {
            throw NSError(
                domain: NSCocoaErrorDomain,
                code: NSFileReadNoSuchFileError,
                userInfo: nil
            )
        }
        return data
    }

    func writeAtomically(data: Data, to url: URL) throws {
        if let error = writeError {
            throw error
        }
        files[url.path] = data
    }
}

// MARK: - Tests

final class PromptRepositoryTests: XCTestCase {
    private var mockFS: MockFileManager!
    private var storageDir: URL!
    private var storageURL: URL!

    override func setUp() {
        super.setUp()
        mockFS = MockFileManager()
        storageDir = URL(fileURLWithPath: "/tmp/test-prompts-\(UUID().uuidString)")
        storageURL = storageDir.appendingPathComponent("prompts.json")
        mockFS.directories.insert(storageDir.path)
    }

    override func tearDown() {
        mockFS = nil
        super.tearDown()
    }

    private func makeRepo() -> PromptRepository {
        PromptRepository(
            fileManager: mockFS,
            storageDirectoryURL: storageDir
        )
    }

    private func makeRepoWithExistingData(_ prompts: [Prompt]) -> PromptRepository {
        let encoder = JSONEncoder()
        // swiftlint:disable:next force_try
        let data = try! encoder.encode(prompts)
        mockFS.files[storageURL.path] = data
        return makeRepo()
    }

    private func makeUserPrompt(
        title: String = "My Prompt",
        sortOrder: Int = 100
    ) -> Prompt {
        Prompt(
            title: title,
            icon: "star",
            template: "Do something with {{text}}",
            resultMode: .replace,
            sortOrder: sortOrder
        )
    }

    // MARK: - test_allPrompts_includesBuiltIns

    func test_allPrompts_includesBuiltIns() {
        let repo = makeRepo()
        let prompts = repo.all()

        XCTAssertEqual(prompts.count, 10)
        XCTAssertTrue(prompts.allSatisfy { $0.isBuiltIn })
        XCTAssertEqual(prompts.first?.title, "Fix Grammar")
    }

    func test_all_returnsBuiltInsOnFirstLaunch() {
        let repo = makeRepo()
        let prompts = repo.all()

        XCTAssertEqual(prompts.count, BuiltInPrompts.all.count)
        let titles = prompts.map(\.title)
        XCTAssertTrue(titles.contains("Fix Grammar"))
        XCTAssertTrue(titles.contains("Explain Code"))
    }

    // MARK: - test_savePrompt_persistsToFile

    func test_savePrompt_persistsToFile() throws {
        let repo = makeRepo()
        let prompt = makeUserPrompt()

        try repo.save(prompt)

        // Verify file was written.
        XCTAssertNotNil(mockFS.files[storageURL.path])

        // Verify the prompt can be retrieved.
        let retrieved = repo.get(id: prompt.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.title, "My Prompt")
    }

    func test_save_appendsToExistingPrompts() throws {
        let repo = makeRepo()
        let prompt1 = makeUserPrompt(title: "First", sortOrder: 100)
        let prompt2 = makeUserPrompt(title: "Second", sortOrder: 101)

        try repo.save(prompt1)
        try repo.save(prompt2)

        let allPrompts = repo.all()
        XCTAssertEqual(allPrompts.count, 12) // 10 built-in + 2 user
    }

    func test_save_updatesExistingPrompt() throws {
        let repo = makeRepo()
        var prompt = makeUserPrompt()
        try repo.save(prompt)

        prompt.title = "Updated Title"
        try repo.save(prompt)

        let retrieved = repo.get(id: prompt.id)
        XCTAssertEqual(retrieved?.title, "Updated Title")
        XCTAssertEqual(repo.all().count, 11) // 10 built-in + 1 user (not duplicated)
    }

    // MARK: - test_deletePrompt_removesFromList

    func test_deletePrompt_removesFromList() throws {
        let repo = makeRepo()
        let prompt = makeUserPrompt()
        try repo.save(prompt)

        XCTAssertEqual(repo.all().count, 11)

        try repo.delete(id: prompt.id)

        XCTAssertEqual(repo.all().count, 10)
        XCTAssertNil(repo.get(id: prompt.id))
    }

    func test_delete_throwsWhenIsBuiltIn() {
        let repo = makeRepo()
        let builtInID = BuiltInPrompts.all[0].id

        XCTAssertThrowsError(try repo.delete(id: builtInID)) { error in
            XCTAssertEqual(
                error as? PromptRepositoryError,
                .cannotDeleteBuiltIn
            )
        }
    }

    func test_delete_throwsWhenNotFound() {
        let repo = makeRepo()
        let randomID = UUID()

        XCTAssertThrowsError(try repo.delete(id: randomID)) { error in
            XCTAssertEqual(
                error as? PromptRepositoryError,
                .promptNotFound(id: randomID)
            )
        }
    }

    // MARK: - test_editBuiltIn_createsPersonalCopy

    func test_editBuiltIn_createsPersonalCopy() throws {
        let repo = makeRepo()
        let builtIn = BuiltInPrompts.all[0]

        // Simulate copy-on-edit: create a personal copy, hide original.
        let personalCopy = Prompt(
            title: builtIn.title + " (edited)",
            icon: builtIn.icon,
            template: builtIn.template,
            resultMode: builtIn.resultMode,
            isBuiltIn: false,
            sortOrder: builtIn.sortOrder
        )
        try repo.save(personalCopy)
        try repo.hide(id: builtIn.id)

        // Original is hidden, personal copy is visible.
        let visible = repo.all()
        XCTAssertFalse(visible.contains { $0.id == builtIn.id })
        XCTAssertTrue(visible.contains { $0.id == personalCopy.id })

        // allIncludingHidden still has both.
        let allPrompts = repo.allIncludingHidden()
        XCTAssertTrue(allPrompts.contains { $0.id == builtIn.id })
        XCTAssertTrue(allPrompts.contains { $0.id == personalCopy.id })
    }

    // MARK: - test_hidePrompt_setsIsHidden

    func test_hidePrompt_setsIsHidden() throws {
        let repo = makeRepo()
        let builtInID = BuiltInPrompts.all[0].id

        try repo.hide(id: builtInID)

        let hidden = repo.get(id: builtInID)
        XCTAssertTrue(hidden?.isHidden == true)

        // all() excludes hidden prompts.
        let visible = repo.all()
        XCTAssertFalse(visible.contains { $0.id == builtInID })
        XCTAssertEqual(visible.count, 9)
    }

    func test_unhide_restoresPrompt() throws {
        let repo = makeRepo()
        let builtInID = BuiltInPrompts.all[0].id

        try repo.hide(id: builtInID)
        XCTAssertEqual(repo.all().count, 9)

        try repo.unhide(id: builtInID)
        XCTAssertEqual(repo.all().count, 10)
        XCTAssertFalse(repo.get(id: builtInID)?.isHidden ?? true)
    }

    func test_hide_nonExistentID_throwsError() {
        let repo = makeRepo()
        let randomID = UUID()

        XCTAssertThrowsError(try repo.hide(id: randomID)) { error in
            XCTAssertEqual(
                error as? PromptRepositoryError,
                .promptNotFound(id: randomID)
            )
        }
    }

    // MARK: - test_searchPrompts_filtersCorrectly

    func test_searchPrompts_filtersCorrectly() {
        let repo = makeRepo()

        let results = repo.search(query: "grammar")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Fix Grammar")
    }

    func test_search_caseInsensitive() {
        let repo = makeRepo()

        let results = repo.search(query: "FIX")
        XCTAssertEqual(results.count, 2) // "Fix Grammar" and "Fix Code"
    }

    func test_search_emptyQuery_returnsAll() {
        let repo = makeRepo()
        let results = repo.search(query: "")
        XCTAssertEqual(results.count, 10)
    }

    func test_search_noMatch_returnsEmpty() {
        let repo = makeRepo()
        let results = repo.search(query: "nonexistent")
        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - test_reorderPrompts_updatesSortOrder

    func test_reorderPrompts_updatesSortOrder() throws {
        let repo = makeRepo()
        let allPrompts = repo.all()

        // Reverse the order of the first 3 prompts.
        let reorderedIDs = [allPrompts[2].id, allPrompts[1].id, allPrompts[0].id]
        try repo.reorder(ids: reorderedIDs)

        let first = repo.get(id: reorderedIDs[0])
        let second = repo.get(id: reorderedIDs[1])
        let third = repo.get(id: reorderedIDs[2])

        XCTAssertEqual(first?.sortOrder, 0)
        XCTAssertEqual(second?.sortOrder, 1)
        XCTAssertEqual(third?.sortOrder, 2)
    }

    // MARK: - test_templateInjection_sanitized

    func test_templateInjection_sanitized() throws {
        let repo = makeRepo()
        let prompt = Prompt(
            title: "Injection Test",
            icon: "star",
            template: "Hello\0World\u{01}\u{02}{{text}}",
            resultMode: .replace,
            sortOrder: 100
        )

        try repo.save(prompt)
        let saved = repo.get(id: prompt.id)

        // Null bytes and control characters should be stripped.
        XCTAssertNotNil(saved)
        XCTAssertFalse(saved!.template.contains("\0")) // swiftlint:disable:this force_unwrapping
        XCTAssertFalse(saved!.template.contains("\u{01}")) // swiftlint:disable:this force_unwrapping
        XCTAssertTrue(saved!.template.contains("{{text}}")) // swiftlint:disable:this force_unwrapping
    }

    func test_templateInjection_lengthLimited() throws {
        let repo = makeRepo()
        let longTemplate = String(repeating: "a", count: 3000)
        let prompt = Prompt(
            title: "Long Template",
            icon: "star",
            template: longTemplate,
            resultMode: .replace,
            sortOrder: 100
        )

        try repo.save(prompt)
        let saved = repo.get(id: prompt.id)

        XCTAssertNotNil(saved)
        XCTAssertEqual(saved!.template.count, 2000) // swiftlint:disable:this force_unwrapping
    }

    // MARK: - Additional tests

    func test_allIncludingHidden_includesHiddenPrompts() throws {
        let repo = makeRepo()
        try repo.hide(id: BuiltInPrompts.all[0].id)

        let allIncluding = repo.allIncludingHidden()
        XCTAssertEqual(allIncluding.count, 10)
        XCTAssertTrue(allIncluding.contains { $0.id == BuiltInPrompts.all[0].id })
    }

    func test_get_returnsPromptByID() {
        let repo = makeRepo()
        let id = BuiltInPrompts.all[0].id
        let prompt = repo.get(id: id)

        XCTAssertNotNil(prompt)
        XCTAssertEqual(prompt?.title, "Fix Grammar")
    }

    func test_get_returnsNilForUnknownID() {
        let repo = makeRepo()
        let prompt = repo.get(id: UUID())
        XCTAssertNil(prompt)
    }

    func test_recentlyUsed_returnsEmptyWhenNoneUsed() {
        let repo = makeRepo()
        let recent = repo.recentlyUsed(limit: 3)
        XCTAssertTrue(recent.isEmpty)
    }

    func test_recentlyUsed_returnsUsedPrompts() throws {
        let repo = makeRepo()

        var prompt = repo.get(id: BuiltInPrompts.all[0].id)!  // swiftlint:disable:this force_unwrapping
        prompt.lastUsedAt = Date()
        try repo.save(prompt)

        let recent = repo.recentlyUsed(limit: 3)
        XCTAssertEqual(recent.count, 1)
        XCTAssertEqual(recent.first?.id, BuiltInPrompts.all[0].id)
    }

    func test_recentlyUsed_respectsLimit() throws {
        let repo = makeRepo()

        for i in 0..<5 {
            var prompt = repo.get(id: BuiltInPrompts.all[i].id)!  // swiftlint:disable:this force_unwrapping
            prompt.lastUsedAt = Date().addingTimeInterval(Double(i))
            try repo.save(prompt)
        }

        let recent = repo.recentlyUsed(limit: 3)
        XCTAssertEqual(recent.count, 3)
    }

    func test_persistenceRoundTrip() throws {
        let repo1 = makeRepo()
        let prompt = makeUserPrompt()
        try repo1.save(prompt)

        // Create second repo loading from same mock filesystem.
        let repo2 = PromptRepository(
            fileManager: mockFS,
            storageDirectoryURL: storageDir
        )
        let loaded = repo2.get(id: prompt.id)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.title, "My Prompt")
    }

    func test_corruptJSON_fallsBackToBuiltIns() {
        mockFS.files[storageURL.path] = Data("not valid json".utf8)

        let repo = makeRepo()
        let prompts = repo.all()

        XCTAssertEqual(prompts.count, 10)
        XCTAssertTrue(prompts.allSatisfy { $0.isBuiltIn })
    }

    func test_promptSortedBySortOrder() throws {
        let repo = makeRepo()

        let prompt1 = Prompt(
            title: "ZZZ First in Sort",
            icon: "star",
            template: "{{text}}",
            resultMode: .replace,
            sortOrder: -1
        )
        try repo.save(prompt1)

        let allPrompts = repo.all()
        XCTAssertEqual(allPrompts.first?.title, "ZZZ First in Sort")
    }
}

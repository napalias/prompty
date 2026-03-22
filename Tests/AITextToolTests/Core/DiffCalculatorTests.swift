// DiffCalculatorTests.swift
// AITextToolTests
//
// Tests for DiffCalculator Myers word-level diff algorithm.
// Pure logic tests, no mocks needed.

import XCTest
@testable import AITextTool

final class DiffCalculatorTests: XCTestCase {

    // MARK: - test_diff_identicalTexts_noChanges

    func test_diff_identicalTexts_noChanges() {
        let text = "Hello world"
        let changes = DiffCalculator.diff(original: text, revised: text)

        // All changes should be .equal
        for change in changes {
            switch change {
            case .equal:
                break
            case .insert, .delete:
                XCTFail("Expected only .equal changes for identical texts, got \(change)")
            }
        }

        // Reconstructed text should match original
        let reconstructed = changes.map { change -> String in
            switch change {
            case .equal(let str): return str
            case .insert(let str): return str
            case .delete: return ""
            }
        }.joined()
        XCTAssertEqual(reconstructed, text)
    }

    // MARK: - test_diff_completelyDifferent

    func test_diff_completelyDifferent() {
        let changes = DiffCalculator.diff(
            original: "alpha beta",
            revised: "gamma delta"
        )

        let deletes = changes.filter {
            if case .delete = $0 { return true }
            return false
        }
        let inserts = changes.filter {
            if case .insert = $0 { return true }
            return false
        }

        // Both words should be deleted and two new words inserted
        XCTAssertGreaterThanOrEqual(deletes.count, 2)
        XCTAssertGreaterThanOrEqual(inserts.count, 2)
    }

    // MARK: - test_diff_wordLevelChanges

    func test_diff_wordLevelChanges() {
        let changes = DiffCalculator.diff(
            original: "The quick brown fox",
            revised: "The slow brown fox"
        )

        let hasDelete = changes.contains { change in
            if case .delete(let str) = change { return str == "quick" }
            return false
        }
        let hasInsert = changes.contains { change in
            if case .insert(let str) = change { return str == "slow" }
            return false
        }

        XCTAssertTrue(hasDelete, "Should delete 'quick'")
        XCTAssertTrue(hasInsert, "Should insert 'slow'")
    }

    // MARK: - test_diff_insertions

    func test_diff_insertions() {
        let changes = DiffCalculator.diff(
            original: "Hello world",
            revised: "Hello beautiful world"
        )

        let inserts = changes.compactMap { change -> String? in
            if case .insert(let str) = change { return str }
            return nil
        }

        XCTAssertTrue(
            inserts.contains("beautiful"),
            "Should insert 'beautiful'"
        )

        // No deletions expected
        let deletes = changes.filter {
            if case .delete = $0 { return true }
            return false
        }
        XCTAssertTrue(deletes.isEmpty, "Should have no deletions")
    }

    // MARK: - test_diff_deletions

    func test_diff_deletions() {
        let changes = DiffCalculator.diff(
            original: "Hello beautiful world",
            revised: "Hello world"
        )

        let deletes = changes.compactMap { change -> String? in
            if case .delete(let str) = change { return str }
            return nil
        }

        XCTAssertTrue(
            deletes.contains("beautiful"),
            "Should delete 'beautiful'"
        )

        // No insertions expected
        let inserts = changes.filter {
            if case .insert = $0 { return true }
            return false
        }
        XCTAssertTrue(inserts.isEmpty, "Should have no insertions")
    }

    // MARK: - test_diff_emptyStrings

    func test_diff_emptyStrings() {
        let changes = DiffCalculator.diff(original: "", revised: "")
        XCTAssertTrue(changes.isEmpty)
    }

    // MARK: - test_diff_emptyOriginal_allInserts

    func test_diff_emptyOriginal_allInserts() {
        let changes = DiffCalculator.diff(
            original: "",
            revised: "Hello world"
        )

        let inserts = changes.filter {
            if case .insert = $0 { return true }
            return false
        }

        XCTAssertFalse(inserts.isEmpty, "Should have insertions")

        // No deletes or equals
        let deletes = changes.filter {
            if case .delete = $0 { return true }
            return false
        }
        XCTAssertTrue(deletes.isEmpty)
    }

    // MARK: - test_diff_emptyRevised_allDeletes

    func test_diff_emptyRevised_allDeletes() {
        let changes = DiffCalculator.diff(
            original: "Hello world",
            revised: ""
        )

        let deletes = changes.filter {
            if case .delete = $0 { return true }
            return false
        }

        XCTAssertFalse(deletes.isEmpty, "Should have deletions")

        // No inserts or equals
        let inserts = changes.filter {
            if case .insert = $0 { return true }
            return false
        }
        XCTAssertTrue(inserts.isEmpty)
    }

    // MARK: - test_tokenize_splitsOnWhitespace

    func test_tokenize_splitsOnWhitespace() {
        let tokens = DiffCalculator.tokenize("Hello, world!")
        XCTAssertEqual(tokens, ["Hello,", " ", "world!"])
    }

    // MARK: - test_tokenize_emptyString_returnsEmpty

    func test_tokenize_emptyString_returnsEmpty() {
        let tokens = DiffCalculator.tokenize("")
        XCTAssertTrue(tokens.isEmpty)
    }

    // MARK: - test_diff_singleWordChange

    func test_diff_singleWordChange() {
        let changes = DiffCalculator.diff(
            original: "cat",
            revised: "dog"
        )

        let hasDelete = changes.contains {
            if case .delete("cat") = $0 { return true }
            return false
        }
        let hasInsert = changes.contains {
            if case .insert("dog") = $0 { return true }
            return false
        }

        XCTAssertTrue(hasDelete, "Should delete 'cat'")
        XCTAssertTrue(hasInsert, "Should insert 'dog'")
    }

    // MARK: - test_diff_complexChanges

    func test_diff_complexChanges() {
        let changes = DiffCalculator.diff(
            original: "The quick brown fox jumps over the lazy dog",
            revised: "The slow brown cat leaps over the happy dog"
        )

        // Verify quick->slow, fox->cat, jumps->leaps, lazy->happy
        let deletes = Set(changes.compactMap { change -> String? in
            if case .delete(let str) = change { return str }
            return nil
        })
        let inserts = Set(changes.compactMap { change -> String? in
            if case .insert(let str) = change { return str }
            return nil
        })

        XCTAssertTrue(deletes.contains("quick"))
        XCTAssertTrue(deletes.contains("fox"))
        XCTAssertTrue(deletes.contains("jumps"))
        XCTAssertTrue(deletes.contains("lazy"))

        XCTAssertTrue(inserts.contains("slow"))
        XCTAssertTrue(inserts.contains("cat"))
        XCTAssertTrue(inserts.contains("leaps"))
        XCTAssertTrue(inserts.contains("happy"))
    }
}

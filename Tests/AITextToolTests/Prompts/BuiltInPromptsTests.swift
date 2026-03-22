// BuiltInPromptsTests.swift
// AITextToolTests
//
// Validates built-in prompt library integrity.

import XCTest
@testable import AITextTool

final class BuiltInPromptsTests: XCTestCase {

    func test_builtInPrompts_containsExactly10() {
        XCTAssertEqual(BuiltInPrompts.all.count, 10)
    }

    func test_builtInPrompts_allAreBuiltIn() {
        XCTAssertTrue(BuiltInPrompts.all.allSatisfy { $0.isBuiltIn })
    }

    func test_builtInPrompts_noneAreHidden() {
        XCTAssertTrue(BuiltInPrompts.all.allSatisfy { !$0.isHidden })
    }

    func test_builtInPrompts_haveUniqueIDs() {
        let ids = BuiltInPrompts.all.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func test_builtInPrompts_haveUniqueTitles() {
        let titles = BuiltInPrompts.all.map(\.title)
        XCTAssertEqual(titles.count, Set(titles).count)
    }

    func test_builtInPrompts_allContainTextPlaceholder() {
        for prompt in BuiltInPrompts.all {
            XCTAssertTrue(
                prompt.template.contains("{{text}}"),
                "\(prompt.title) template should contain {{text}}"
            )
        }
    }

    func test_builtInPrompts_sortOrderIsSequential() {
        let sortOrders = BuiltInPrompts.all.map(\.sortOrder)
        XCTAssertEqual(sortOrders, Array(0..<10))
    }

    func test_builtInPrompts_expectedTitles() {
        let titles = BuiltInPrompts.all.map(\.title)
        let expected = [
            "Fix Grammar",
            "Improve Writing",
            "Simplify",
            "Make Professional",
            "Summarize",
            "Explain",
            "Translate to English",
            "Convert to Bullet Points",
            "Fix Code",
            "Explain Code"
        ]
        XCTAssertEqual(titles, expected)
    }

    func test_builtInPrompts_areCodable() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(BuiltInPrompts.all)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode([Prompt].self, from: data)

        XCTAssertEqual(decoded, BuiltInPrompts.all)
    }

    func test_builtInPrompts_haveSFSymbolIcons() {
        for prompt in BuiltInPrompts.all {
            XCTAssertFalse(
                prompt.icon.isEmpty,
                "\(prompt.title) should have an icon"
            )
        }
    }
}

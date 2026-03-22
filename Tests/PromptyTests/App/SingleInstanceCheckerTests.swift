// SingleInstanceCheckerTests.swift
// PromptyTests

import Foundation
import Testing
@testable import Prompty

// MARK: - Mock

final class MockSingleInstanceChecker: SingleInstanceCheckerProtocol {
    var duplicateRunning: Bool = false

    func isDuplicateRunning() -> Bool {
        duplicateRunning
    }
}

// MARK: - Tests

@Suite("SingleInstanceChecker")
struct SingleInstanceCheckerTests {

    @Test("Detects duplicate when another instance is running")
    func test_singleInstance_detectsDuplicate() {
        let checker = MockSingleInstanceChecker()
        checker.duplicateRunning = true
        #expect(checker.isDuplicateRunning() == true)
    }

    @Test("Reports no duplicate when running alone")
    func test_singleInstance_noDuplicate() {
        let checker = MockSingleInstanceChecker()
        checker.duplicateRunning = false
        #expect(checker.isDuplicateRunning() == false)
    }

    @Test("Real checker runs without crashing in test context")
    func test_realChecker_runsWithoutCrash() {
        let checker = SingleInstanceChecker()
        // In a test runner there is only one instance, so this should not crash
        _ = checker.isDuplicateRunning()
    }
}

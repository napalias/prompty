// HotkeyManagerTests.swift
// PromptyTests

import XCTest
@testable import Prompty

// Uses MockHotkeyManager because real CGEventTap requires Input Monitoring
// permission, which is unavailable in CI/test environments.

/// Thread-safe call counter for use in @Sendable closures.
private final class CallCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: Int = 0

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }

    func increment() {
        lock.lock()
        _value += 1
        lock.unlock()
    }
}

final class HotkeyManagerTests: XCTestCase {

    private var sut: MockHotkeyManager!

    override func setUp() {
        super.setUp()
        sut = MockHotkeyManager()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Registration

    func test_register_setsIsRegisteredTrue() throws {
        XCTAssertFalse(sut.isRegistered)

        try sut.register(keyCode: 49, modifiers: .maskAlternate)

        XCTAssertTrue(sut.isRegistered)
    }

    func test_unregister_setsIsRegisteredFalse() throws {
        try sut.register(keyCode: 49, modifiers: .maskAlternate)
        XCTAssertTrue(sut.isRegistered)

        sut.unregister()

        XCTAssertFalse(sut.isRegistered)
    }

    func test_unregister_whenNotRegistered_doesNotThrow() {
        XCTAssertFalse(sut.isRegistered)

        // Should not throw or crash
        sut.unregister()

        XCTAssertFalse(sut.isRegistered)
    }

    func test_register_twice_replacesExisting() throws {
        try sut.register(keyCode: 49, modifiers: .maskAlternate)
        XCTAssertTrue(sut.isRegistered)
        XCTAssertEqual(sut.registerCallCount, 1)

        try sut.register(keyCode: 36, modifiers: .maskCommand)
        XCTAssertTrue(sut.isRegistered)
        XCTAssertEqual(sut.registerCallCount, 2)
        XCTAssertEqual(sut.lastRegisteredKeyCode, 36)
    }

    // MARK: - Handler Callback

    func test_handler_calledOnHotkeyFire() throws {
        let expectation = expectation(description: "Handler called")
        try sut.register(keyCode: 49, modifiers: .maskAlternate)

        sut.onHotkeyFired = {
            expectation.fulfill()
        }

        sut.simulateFire()

        wait(for: [expectation], timeout: 1.0)
    }

    func test_mockFire_callsHandler() {
        let callCount = CallCounter()
        sut.onHotkeyFired = {
            callCount.increment()
        }

        sut.simulateFire()
        sut.simulateFire()

        XCTAssertEqual(callCount.value, 2)
    }

    func test_mockFire_withNoHandler_doesNotCrash() {
        sut.onHotkeyFired = nil

        // Should not crash
        sut.simulateFire()
    }

    // MARK: - Reregister (19B sleep/wake)

    func test_reregister_setsIsRegisteredTrue() throws {
        try sut.reregister()

        XCTAssertTrue(sut.isRegistered)
        XCTAssertEqual(sut.reregisterCallCount, 1)
    }
}

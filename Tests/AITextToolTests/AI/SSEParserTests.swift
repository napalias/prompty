// SSEParserTests.swift
// AITextToolTests
//
// Tests for SSE line parser — pure logic, no mocks needed.

import XCTest
@testable import AITextTool

final class SSEParserTests: XCTestCase {

    // MARK: - Skip Cases

    func test_extractData_returnsSkipForEmptyLine() {
        let result = SSEParser.extractData(from: "")
        XCTAssertEqual(result, .skip)
    }

    func test_extractData_returnsSkipForCommentLine() {
        let result = SSEParser.extractData(from: ": this is a comment")
        XCTAssertEqual(result, .skip)
    }

    func test_extractData_returnsSkipForNonDataField() {
        let result = SSEParser.extractData(from: "event: message")
        XCTAssertEqual(result, .skip)
    }

    // MARK: - Done Signal

    func test_extractData_returnsDoneForDoneLine() {
        let result = SSEParser.extractData(from: "data: [DONE]")
        XCTAssertEqual(result, .done)
    }

    // MARK: - Data Extraction

    func test_extractData_returnsDataForValidDataLine() {
        let json = #"{"type":"content_block_delta"}"#
        let result = SSEParser.extractData(from: "data: \(json)")
        XCTAssertEqual(result, .data(json))
    }

    func test_extractData_stripsDataPrefix() {
        let result = SSEParser.extractData(from: "data: hello")
        XCTAssertEqual(result, .data("hello"))
    }

    func test_extractData_handlesLineWithSpaceAfterColon() {
        // With space (conventional)
        let result = SSEParser.extractData(from: "data: value")
        XCTAssertEqual(result, .data("value"))

        // Without space (also valid per SSE spec)
        let result2 = SSEParser.extractData(from: "data:value")
        XCTAssertEqual(result2, .data("value"))
    }

    func test_extractData_handlesMultipleColonsInPayload() {
        let json = #"{"key":"val:ue","other":"data:stuff"}"#
        let result = SSEParser.extractData(from: "data: \(json)")
        XCTAssertEqual(result, .data(json))
    }

    // MARK: - Edge Cases

    func test_extractData_handlesEmptyDataPayload() {
        let result = SSEParser.extractData(from: "data: ")
        XCTAssertEqual(result, .data(""))
    }

    func test_extractData_handlesDataWithNoSpace() {
        let result = SSEParser.extractData(from: "data:")
        XCTAssertEqual(result, .data(""))
    }

    func test_extractData_ignoresRetryField() {
        let result = SSEParser.extractData(from: "retry: 3000")
        XCTAssertEqual(result, .skip)
    }

    func test_extractData_ignoresIdField() {
        let result = SSEParser.extractData(from: "id: 12345")
        XCTAssertEqual(result, .skip)
    }
}

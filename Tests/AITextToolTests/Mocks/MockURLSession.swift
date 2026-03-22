// MockURLSession.swift
// AITextToolTests
//
// Mock URLSession for testing AI providers without real network calls.

import Foundation
@testable import AITextTool

/// Returns pre-configured responses for testing AI providers.
final class MockURLSession: URLSessionProtocol, @unchecked Sendable {

    /// HTTP status code to return. Defaults to 200.
    var statusCode: Int = 200

    /// Raw string lines to deliver via the async bytes stream.
    var responseLines: [String] = []

    /// If set, the bytes call throws this error instead.
    var errorToThrow: Error?

    /// The last URLRequest received (for header/body inspection).
    var lastRequest: URLRequest?

    func bytes(
        for request: URLRequest
    ) async throws -> (URLSession.AsyncBytes, URLResponse) {
        lastRequest = request

        if let error = errorToThrow {
            throw error
        }

        let response = HTTPURLResponse(
            url: request.url ?? URL(string: "https://test")!,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!

        let rawString = responseLines.joined(separator: "\n")
        let data = rawString.data(using: .utf8) ?? Data()
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try data.write(to: tempFile)

        // Create AsyncBytes from a file URL via real URLSession
        let (bytes, _) = try await URLSession.shared.bytes(
            from: tempFile
        )

        try? FileManager.default.removeItem(at: tempFile)

        return (bytes, response as URLResponse)
    }
}

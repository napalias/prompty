// SSEParser.swift
// AITextTool
//
// Server-Sent Events line parser for Anthropic and OpenAI streaming.

import Foundation

/// Represents a parsed SSE line.
enum SSELine: Equatable {
    /// Raw JSON string from a data line.
    case data(String)
    /// Stream complete signal.
    case done
    /// Comment, empty line, or non-data field to ignore.
    case skip
}

/// Parses raw SSE lines and extracts data payloads.
struct SSEParser {
    /// Parses a single SSE line and returns the appropriate SSELine case.
    static func extractData(from line: String) -> SSELine {
        // TODO: Implement SSE parsing
        .skip
    }
}

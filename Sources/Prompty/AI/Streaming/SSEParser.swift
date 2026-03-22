// SSEParser.swift
// Prompty
//
// Server-Sent Events line parser for Anthropic and OpenAI streaming.
// SSE spec: https://html.spec.whatwg.org/multipage/server-sent-events.html

import Foundation

// MARK: - SSELine

/// Represents a parsed SSE line.
enum SSELine: Equatable, Sendable {
    /// Raw JSON string from a data line.
    case data(String)
    /// Stream complete signal ([DONE]).
    case done
    /// Comment, empty line, or non-data field to ignore.
    case skip
}

// MARK: - SSEParser

/// Parses raw SSE lines and extracts data payloads.
struct SSEParser: Sendable {

    /// Parses a single SSE line and returns the appropriate SSELine case.
    ///
    /// - Returns `.data` for lines starting with `data:` (payload extracted).
    /// - Returns `.done` for the special `data: [DONE]` line (OpenAI convention).
    /// - Returns `.skip` for comments (`:` prefix), empty lines, and non-data fields.
    static func extractData(from line: String) -> SSELine {
        let trimmed = line.trimmingCharacters(in: .newlines)

        // Empty line separates events in SSE but carries no data
        guard !trimmed.isEmpty else { return .skip }

        // Comment lines start with ':'
        guard !trimmed.hasPrefix(":") else { return .skip }

        // Only process "data:" field; skip "event:", "id:", "retry:" etc.
        guard trimmed.hasPrefix("data:") else { return .skip }

        // Extract payload after "data:" — spec says optional space after colon
        let afterPrefix = trimmed.dropFirst("data:".count)
        let payload: String
        if afterPrefix.hasPrefix(" ") {
            payload = String(afterPrefix.dropFirst())
        } else {
            payload = String(afterPrefix)
        }

        // OpenAI uses "[DONE]" to signal stream end
        if payload == "[DONE]" {
            return .done
        }

        return .data(payload)
    }
}

// AIResponse.swift
// Prompty
//
// Represents a streaming token or final result from an AI provider.

import Foundation

/// A single streaming event from an AI provider response.
struct AIResponse: Sendable, Equatable {
    /// The text token received in this streaming chunk.
    let token: String
    /// Whether this is the final event in the stream.
    let isDone: Bool
}

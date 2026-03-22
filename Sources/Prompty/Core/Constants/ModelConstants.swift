// ModelConstants.swift
// Prompty
//
// Default model names and available model lists per provider (21G).

import Foundation

enum ModelConstants {
    enum Anthropic {
        static let defaultModel = "claude-opus-4-5"
        static let availableModels = [
            "claude-opus-4-5",
            "claude-sonnet-4-5",
            "claude-haiku-4-5"
        ]
    }

    enum OpenAI {
        static let defaultModel = "gpt-4o"
        static let availableModels = [
            "gpt-4o",
            "gpt-4o-mini",
            "gpt-4-turbo",
            "o1-preview",
            "o1-mini"
        ]
    }
}

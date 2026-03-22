// BuiltInPrompts.swift
// AITextTool
//
// Static default prompt library (10 prompts). These cannot be deleted, only hidden.

import Foundation

enum BuiltInPrompts {

    // Deterministic date for built-in prompts so they are always equal.
    // swiftlint:disable:next force_unwrapping
    private static let epoch = ISO8601DateFormatter().date(from: "2025-01-01T00:00:00Z")!

    // swiftlint:disable force_unwrapping
    static let all: [Prompt] = [
        Prompt(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            title: "Fix Grammar",
            icon: "text.badge.checkmark",
            template: "Fix the grammar and spelling in the following text, preserving the original meaning and tone:\n\n{{text}}",
            resultMode: .replace,
            renderMode: .plain,
            pasteMode: .plain,
            isBuiltIn: true,
            isHidden: false,
            sortOrder: 0,
            createdAt: epoch,
            modifiedAt: epoch
        ),
        Prompt(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            title: "Improve Writing",
            icon: "pencil.and.outline",
            template: "Improve the writing quality of the following text. Make it clearer, more concise, and more professional:\n\n{{text}}",
            resultMode: .diff,
            renderMode: .markdown,
            pasteMode: .plain,
            isBuiltIn: true,
            isHidden: false,
            sortOrder: 1,
            createdAt: epoch,
            modifiedAt: epoch
        ),
        Prompt(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            title: "Simplify",
            icon: "text.redaction",
            template: "Simplify the following text so it is easy to understand. Use short sentences and common words:\n\n{{text}}",
            resultMode: .diff,
            renderMode: .plain,
            pasteMode: .plain,
            isBuiltIn: true,
            isHidden: false,
            sortOrder: 2,
            createdAt: epoch,
            modifiedAt: epoch
        ),
        Prompt(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            title: "Make Professional",
            icon: "briefcase",
            template: "Rewrite the following text in a formal, professional tone:\n\n{{text}}",
            resultMode: .diff,
            renderMode: .plain,
            pasteMode: .plain,
            isBuiltIn: true,
            isHidden: false,
            sortOrder: 3,
            createdAt: epoch,
            modifiedAt: epoch
        ),
        Prompt(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            title: "Summarize",
            icon: "text.compress",
            template: "Summarize the following text in 2-3 sentences:\n\n{{text}}",
            resultMode: .copy,
            renderMode: .markdown,
            pasteMode: .plain,
            isBuiltIn: true,
            isHidden: false,
            sortOrder: 4,
            createdAt: epoch,
            modifiedAt: epoch
        ),
        Prompt(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
            title: "Explain",
            icon: "questionmark.circle",
            template: "Explain the following in simple, clear terms:\n\n{{text}}",
            resultMode: .continueChat,
            renderMode: .markdown,
            pasteMode: .plain,
            isBuiltIn: true,
            isHidden: false,
            sortOrder: 5,
            createdAt: epoch,
            modifiedAt: epoch
        ),
        Prompt(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
            title: "Translate to English",
            icon: "globe",
            template: "Translate the following text to English:\n\n{{text}}",
            resultMode: .replace,
            renderMode: .plain,
            pasteMode: .plain,
            isBuiltIn: true,
            isHidden: false,
            sortOrder: 6,
            createdAt: epoch,
            modifiedAt: epoch
        ),
        Prompt(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!,
            title: "Convert to Bullet Points",
            icon: "list.bullet",
            template: "Convert the following text into a concise bulleted list:\n\n{{text}}",
            resultMode: .copy,
            renderMode: .markdown,
            pasteMode: .plain,
            isBuiltIn: true,
            isHidden: false,
            sortOrder: 7,
            createdAt: epoch,
            modifiedAt: epoch
        ),
        Prompt(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000009")!,
            title: "Fix Code",
            icon: "hammer",
            template: "Fix any bugs in the following code. Return only the corrected code with no explanation:\n\n{{text}}",
            resultMode: .replace,
            renderMode: .code,
            pasteMode: .plain,
            isBuiltIn: true,
            isHidden: false,
            sortOrder: 8,
            createdAt: epoch,
            modifiedAt: epoch
        ),
        Prompt(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000000a")!,
            title: "Explain Code",
            icon: "doc.text.magnifyingglass",
            template: "Explain the following code in plain language. Describe what it does, step by step:\n\n{{text}}",
            resultMode: .continueChat,
            renderMode: .markdown,
            pasteMode: .plain,
            isBuiltIn: true,
            isHidden: false,
            sortOrder: 9,
            createdAt: epoch,
            modifiedAt: epoch
        )
    ]
    // swiftlint:enable force_unwrapping
}

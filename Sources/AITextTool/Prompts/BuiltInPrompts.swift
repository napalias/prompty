// BuiltInPrompts.swift
// AITextTool
//
// Static default prompt library. These cannot be deleted, only hidden.

import Foundation

enum BuiltInPrompts {
    static let all: [Prompt] = [
        Prompt(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID(),
            title: "Fix Grammar",
            icon: "text.badge.checkmark",
            template: "Fix the grammar and spelling in the following text, preserving the original meaning and tone:\n\n{text}",
            resultMode: .replace,
            renderMode: .plain,
            pasteMode: .plain,
            isBuiltIn: true,
            isHidden: false,
            sortOrder: 0
        ),
        Prompt(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002") ?? UUID(),
            title: "Improve Writing",
            icon: "pencil.and.outline",
            template: "Improve the writing quality of the following text. Make it clearer, more concise, and more professional:\n\n{text}",
            resultMode: .diff,
            renderMode: .markdown,
            pasteMode: .plain,
            isBuiltIn: true,
            isHidden: false,
            sortOrder: 1
        ),
        Prompt(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003") ?? UUID(),
            title: "Summarise",
            icon: "text.compress",
            template: "Summarise the following text in 2-3 sentences:\n\n{text}",
            resultMode: .copy,
            renderMode: .markdown,
            pasteMode: .plain,
            isBuiltIn: true,
            isHidden: false,
            sortOrder: 2
        ),
        Prompt(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004") ?? UUID(),
            title: "Translate to EN",
            icon: "globe",
            template: "Translate the following text to English:\n\n{text}",
            resultMode: .replace,
            renderMode: .plain,
            pasteMode: .plain,
            isBuiltIn: true,
            isHidden: false,
            sortOrder: 3
        ),
        Prompt(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005") ?? UUID(),
            title: "Explain",
            icon: "questionmark.circle",
            template: "Explain the following in simple, clear terms:\n\n{text}",
            resultMode: .continueChat,
            renderMode: .markdown,
            pasteMode: .plain,
            isBuiltIn: true,
            isHidden: false,
            sortOrder: 4
        ),
        Prompt(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000006") ?? UUID(),
            title: "Fix Code",
            icon: "hammer",
            template: "Fix any bugs in the following code. Return only the corrected code with no explanation:\n\n{text}",
            resultMode: .replace,
            renderMode: .code,
            pasteMode: .plain,
            isBuiltIn: true,
            isHidden: false,
            sortOrder: 5
        ),
        Prompt(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000007") ?? UUID(),
            title: "Make Formal",
            icon: "briefcase",
            template: "Rewrite the following text in a formal, professional tone:\n\n{text}",
            resultMode: .diff,
            renderMode: .plain,
            pasteMode: .plain,
            isBuiltIn: true,
            isHidden: false,
            sortOrder: 6
        ),
        Prompt(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000008") ?? UUID(),
            title: "Make Casual",
            icon: "face.smiling",
            template: "Rewrite the following text in a friendly, casual tone:\n\n{text}",
            resultMode: .diff,
            renderMode: .plain,
            pasteMode: .plain,
            isBuiltIn: true,
            isHidden: false,
            sortOrder: 7
        ),
        Prompt(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000009") ?? UUID(),
            title: "Continue Writing",
            icon: "text.append",
            template: "Continue writing from where the following text ends, matching the style and tone:\n\n{text}",
            resultMode: .continueChat,
            renderMode: .markdown,
            pasteMode: .plain,
            isBuiltIn: true,
            isHidden: false,
            sortOrder: 8
        ),
        Prompt(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000000a") ?? UUID(),
            title: "Custom",
            icon: "slider.horizontal.3",
            template: "{input}\n\n{text}",
            resultMode: .continueChat,
            renderMode: .markdown,
            pasteMode: .plain,
            isBuiltIn: true,
            isHidden: false,
            sortOrder: 9
        )
    ]
}

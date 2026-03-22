// PanelModeTests.swift
// PromptyTests
//
// Tests verifying PanelMode enum has all expected cases per spec 21K.

import Foundation
import Testing
@testable import Prompty

@Suite("PanelMode")
struct PanelModeTests {

    // MARK: - All Cases Present

    @Test("PanelMode has all 9 expected cases from spec 21K")
    func test_allExpectedCasesExist() {
        // Verify each case can be constructed
        let cases: [PanelMode] = [
            .promptPicker,
            .customInput,
            .streaming,
            .diff,
            .continueChat,
            .editBeforeReplace,
            .error,
            .noProviderConfigured,
            .promptEditor(prompt: nil, isNew: true)
        ]

        #expect(cases.count == 9)
    }

    // MARK: - Equatable

    @Test("Simple cases are equal to themselves")
    func test_simpleCases_areEqualToThemselves() {
        #expect(PanelMode.promptPicker == .promptPicker)
        #expect(PanelMode.customInput == .customInput)
        #expect(PanelMode.streaming == .streaming)
        #expect(PanelMode.diff == .diff)
        #expect(PanelMode.continueChat == .continueChat)
        #expect(PanelMode.editBeforeReplace == .editBeforeReplace)
        #expect(PanelMode.error == .error)
        #expect(PanelMode.noProviderConfigured == .noProviderConfigured)
    }

    @Test("Different simple cases are not equal")
    func test_differentSimpleCases_areNotEqual() {
        #expect(PanelMode.promptPicker != .streaming)
        #expect(PanelMode.error != .diff)
        #expect(PanelMode.customInput != .continueChat)
    }

    @Test("promptEditor equality compares prompt id and isNew flag")
    func test_promptEditor_equalityComparesByIdAndIsNew() {
        let id = UUID()
        let prompt = Prompt(
            id: id,
            title: "Test",
            icon: "star",
            template: "{text}",
            resultMode: .replace,
            renderMode: .plain,
            pasteMode: .plain,
            providerOverride: nil,
            systemPromptOverride: nil,
            isBuiltIn: false,
            isHidden: false,
            sortOrder: 0,
            lastUsedAt: nil
        )

        let modeA = PanelMode.promptEditor(prompt: prompt, isNew: true)
        let modeB = PanelMode.promptEditor(prompt: prompt, isNew: true)
        let modeC = PanelMode.promptEditor(prompt: prompt, isNew: false)
        let modeD = PanelMode.promptEditor(prompt: nil, isNew: true)

        #expect(modeA == modeB)
        #expect(modeA != modeC)
        #expect(modeA != modeD)
    }

    @Test("promptEditor with nil prompts and same isNew are equal")
    func test_promptEditor_nilPrompts_areEqual() {
        let modeA = PanelMode.promptEditor(prompt: nil, isNew: true)
        let modeB = PanelMode.promptEditor(prompt: nil, isNew: true)

        #expect(modeA == modeB)
    }

    @Test("promptEditor is not equal to simple cases")
    func test_promptEditor_notEqualToSimpleCases() {
        let mode = PanelMode.promptEditor(prompt: nil, isNew: true)

        #expect(mode != .promptPicker)
        #expect(mode != .error)
    }
}

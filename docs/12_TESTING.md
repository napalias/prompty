# 12 — Testing Strategy

## Philosophy
- Test behaviour, not implementation
- Every public function on every service/repository MUST have at least one test
- Mock all I/O (network, filesystem, Keychain, AX API, clipboard)
- No test may depend on the filesystem, network, or system state
- Tests must be deterministic (no `sleep`, use injected clocks)

## Test Targets

### Unit Tests: `AITextToolTests`
Fast, isolated, no real I/O.

### Integration Tests: `AITextToolIntegrationTests`  
Tests that wire two or more real modules together (no mocks), but still no real network.
Run separately: `xcodebuild test -only-testing:AITextToolIntegrationTests`

---

## Required Tests Per Module

### HotkeyManager
```
✅ HotkeyManagerTests
  - test_register_setsIsRegisteredTrue
  - test_unregister_setsIsRegisteredFalse
  - test_unregister_whenNotRegistered_doesNotThrow
  - test_onHotkeyFired_calledOnMainThread
  - test_mockFire_callsHandler  (MockHotkeyManager only)
```

### AccessibilityReader
```
✅ AccessibilityReaderTests
  - test_readSelectedText_returnsNilWhenNoFocusedElement (mock AX returning failure)
  - test_readSelectedText_returnsNilForEmptyString
  - test_readSelectedText_returnsTextWhenAvailable
```

### ClipboardFallbackReader
```
✅ ClipboardFallbackReaderTests
  - test_read_returnsTextWhenClipboardChanges
  - test_read_throwsNoTextSelected_whenClipboardUnchanged
  - test_read_restoresOriginalClipboardContents
  - test_read_usesInjectedWaitDuration (fast test: inject .milliseconds(0))
```

### TextCaptureService
```
✅ TextCaptureServiceTests
  - test_capture_returnsAXResultWhenAvailable
  - test_capture_fallsBackToClipboardWhenAXReturnsNil
  - test_capture_throwsPermissionDenied_whenAXNotGranted
  - test_capture_throwsNoTextSelected_whenBothFail
```

### SSEParser
```
✅ SSEParserTests  ← most extensive, pure logic
  - test_extractData_returnsSkipForEmptyLine
  - test_extractData_returnsSkipForCommentLine
  - test_extractData_returnsDoneForDoneLine
  - test_extractData_returnsDataForValidDataLine
  - test_extractData_stripsDataPrefix
  - test_extractData_handlesLineWithSpaceAfterColon
  - test_extractData_handlesMultipleColonsInPayload
  - test_extractData_returnsSkipForNonDataField (e.g. "event: ...")
```

### AnthropicProvider
```
✅ AnthropicProviderTests (mock URLSession)
  - test_stream_sendsCorrectHeaders
  - test_stream_sendsCorrectRequestBody
  - test_stream_yieldsTokensFromSSEResponse
  - test_stream_completesOnMessageStop
  - test_stream_throwsAPIError_on4xxResponse
  - test_stream_throwsAPIKeyInvalid_on401Response
  - test_stream_throwsRateLimitExceeded_on429Response
  - test_stream_throwsNetworkUnavailable_onURLError
  - test_isConfigured_falseWhenKeyIsEmpty
  - test_isConfigured_trueWhenKeyIsSet
```

### OpenAIProvider
```
✅ OpenAIProviderTests (same pattern as Anthropic)
  - test_stream_sendsCorrectHeaders
  - test_stream_sendsCorrectRequestBody
  - test_stream_yieldsTokensFromSSEResponse
  - test_stream_completesOnDONELine
  - test_stream_throwsAPIError_on4xxResponse
  - test_stream_throwsAPIKeyInvalid_on401Response
  - test_stream_throwsRateLimitExceeded_on429Response
  - test_isConfigured_falseWhenKeyIsEmpty
```

### OllamaProvider
```
✅ OllamaProviderTests (mock URLSession)
  - test_isConfigured_checksPingEndpoint
  - test_isConfigured_falseOnConnectionRefused
  - test_stream_yieldsTokensFromNDJSONResponse
  - test_stream_completesOnDoneTrue
  - test_stream_throwsOllamaNotRunning_onConnectionRefused
```

### AIProviderManager
```
✅ AIProviderManagerTests (all providers mocked)
  - test_stream_delegatesToActiveProvider
  - test_stream_throwsProviderNotConfigured_whenProviderMissing
  - test_stream_throwsProviderNotConfigured_whenProviderNotConfigured
  - test_setActiveProvider_changesActiveProvider
```

### PromptRepository
```
✅ PromptRepositoryTests (mock filesystem)
  - test_all_returnsBuiltInsOnFirstLaunch
  - test_add_persistsPrompt
  - test_add_appendsToExistingPrompts
  - test_update_replacesExistingPrompt
  - test_update_throwsWhenIDNotFound
  - test_delete_removesPrompt
  - test_delete_throwsWhenIsBuiltIn
  - test_reorder_appliesSortOrder
```

### SettingsRepository
```
✅ SettingsRepositoryTests (mock UserDefaults via in-memory suite)
  - test_load_returnsDefaultsOnFirstLaunch
  - test_save_persistsSettings
  - test_load_afterSave_returnsPersistedSettings
  - test_save_throwsOnEncodeFailure (inject broken encoder)
```

### KeychainService
```
✅ KeychainServiceTests (mock Security framework calls)
  - test_set_storesValue
  - test_get_returnsStoredValue
  - test_get_returnsNilWhenNotFound
  - test_delete_removesValue
  - test_set_overwritesExistingValue
  - test_get_throwsOnKeychainError
```

### TextReplaceService
```
✅ TextReplaceServiceTests
  - test_replace_usesAXWriterWhenAvailable
  - test_replace_fallsBackToClipboardPaste_whenAXFails
  - test_copyToClipboard_setsClipboardContents
```

### DiffCalculator
```
✅ DiffCalculatorTests (pure logic — no mocks needed)
  - test_diff_emptyStrings
  - test_diff_identicalStrings_returnsNoChanges
  - test_diff_singleWordChange
  - test_diff_addedWords
  - test_diff_removedWords
  - test_diff_complexChanges
```

### PromptFormatter (template substitution)
```
✅ PromptFormatterTests (pure logic — no mocks needed)
  - test_buildUserMessage_substitutesTextPlaceholder
  - test_buildUserMessage_substitutesInputPlaceholder
  - test_buildUserMessage_appendsTextWhenNoPlaceholder
  - test_buildUserMessage_selectedTextContainsPlaceholderString_doesNotDoubleSubstitute
  - test_buildUserMessage_emptySelectedText_handledGracefully
  - test_buildUserMessage_bothPlaceholdersPresent_bothSubstituted
```

### Performance Tests
```
✅ PerformanceTests
  - test_hotkeyToCapture_under50ms
    // Uses XCTMeasure. Mocks AX reader returning immediately.
    // Asserts capture completes in < 50ms (leaves 150ms budget for panel show)
  - test_promptPickerRender_under16ms
    // Uses XCTMeasure. Renders PromptPickerView with 20 prompts.
    // Asserts render completes in < 16ms (60fps budget)
```

### Integration Tests (AITextToolIntegrationTests target)
```
✅ FullFlowIntegrationTests
  - test_hotkeyFires_textCaptured_promptSelected_streamedResult_replacedInSource
    // Wires: MockHotkeyManager → real TextCaptureService (mocked AX) →
    //        real AIProviderManager (MockAIProvider) → real AppState →
    //        real TextReplaceService (mocked AX writer)
    // Asserts: after Enter, AppState.panelMode == .promptPicker (dismissed)
    // Asserts: MockAXWriter received the AI result string
  - test_streamCancellation_midStream_cleanupComplete
    // Fires hotkey, starts stream, cancels after 3 tokens
    // Asserts: Task is nil, isStreaming is false, partial tokens visible
  - test_retryLogic_on503_retriesOnce_thenSucceeds
    // MockProvider fails first call with 503, succeeds on second
    // Asserts: user sees result (not error), 2 provider.stream() calls made
```

---

## Mock Implementations

Every mock lives in `AITextToolTests/Mocks/` and is NOT in the main target.

```swift
// Example mock
final class MockAIProvider: AIProviderProtocol {
    let id = "mock"
    let displayName = "Mock"
    var mockIsConfigured = true
    var isConfigured: Bool { mockIsConfigured }

    // Injected response for testing
    var stubbedTokens: [String] = ["Hello", " world"]
    var stubbedError: Error? = nil

    func stream(request: AIRequest) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                if let error = stubbedError {
                    continuation.finish(throwing: error)
                    return
                }
                for token in stubbedTokens {
                    continuation.yield(token)
                }
                continuation.finish()
            }
        }
    }
}
```

---

## How to Run Tests

```bash
# All unit tests
xcodebuild test \
  -scheme AITextTool \
  -destination 'platform=macOS' \
  -resultBundlePath TestResults.xcresult

# Single test file
xcodebuild test \
  -scheme AITextTool \
  -destination 'platform=macOS' \
  -only-testing:AITextToolTests/SSEParserTests

# With coverage report
xcodebuild test \
  -scheme AITextTool \
  -destination 'platform=macOS' \
  -enableCodeCoverage YES

# Lint
swiftlint lint --strict --reporter json > lint_report.json
```

## UserDefaults Test Isolation Rule

`SettingsRepository` MUST accept an injected `UserDefaults` instance.
Tests always inject `UserDefaults(suiteName: "test-\(UUID().uuidString)")!`
and call `.removePersistentDomain(forName:)` in `tearDown()`.

**Never inject `UserDefaults.standard` into tests.** Real user settings
would be modified and persist across test runs.

```swift
// SettingsRepositoryTests.swift pattern
class SettingsRepositoryTests: XCTestCase {
    var suiteName: String!
    var defaults: UserDefaults!
    var repo: SettingsRepository!

    override func setUp() {
        suiteName = "test-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        repo = SettingsRepository(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
    }
}
```

## Coverage Requirement
- All service/repository/utility files: **minimum 80% line coverage**
- Models and protocols: exempt (trivial)
- UI views: exempt (SwiftUI previews provide visual coverage)
  - **However:** all `#Preview` blocks MUST use `PreviewData.swift` — never hardcoded literals
  - `PreviewData.swift` contains: `sampleText`, `samplePrompts`, `sampleStreamingTokens`,
    `sampleConversation`, `sampleError` — used consistently across all previews
- Review agent MUST check coverage report and FAIL if any service is below 80%

---

## Test Naming Convention
```
test_<methodName>_<condition>_<expectedResult>

Examples:
  test_capture_whenAXGranted_returnsSelectedText
  test_stream_on401Response_throwsAPIKeyInvalid
  test_delete_whenBuiltIn_throwsError
```

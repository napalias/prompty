# 08 — Module: AI Providers

## Core Models

```swift
// AIMessage.swift
struct AIMessage: Codable, Equatable, Sendable {
    enum Role: String, Codable { case user, assistant, system }
    let role: Role
    let content: String
}

// AIRequest.swift
struct AIRequest: Sendable {
    let systemPrompt: String?       // optional system prompt from prompt template
    let userPrompt: String          // the built prompt string (template filled in)
    let selectedText: String        // raw captured text
    let history: [AIMessage]        // for continue-chat mode; empty for first turn
}

// Provider config
struct ProviderConfig: Codable {
    let providerID: String
    var isEnabled: Bool
    var modelOverride: String?      // nil = use provider default
}
```

---

## AIProviderProtocol

```swift
protocol AIProviderProtocol: Sendable {
    var id: String { get }
    var displayName: String { get }
    var isConfigured: Bool { get }  // false = missing API key / not logged in

    /// Streams response tokens. Throws AppError on failure.
    func stream(request: AIRequest) -> AsyncThrowingStream<String, Error>
}
```

---

## AIProviderManager

```swift
// AIProviderManager.swift
// Responsibility: holds all registered providers, delegates to active one

@Observable
final class AIProviderManager {
    private(set) var providers: [any AIProviderProtocol]
    var activeProviderID: String

    var activeProvider: (any AIProviderProtocol)? {
        providers.first { $0.id == activeProviderID }
    }

    func stream(request: AIRequest) -> AsyncThrowingStream<String, Error> {
        guard let provider = activeProvider else {
            return AsyncThrowingStream { $0.finish(throwing: AppError.providerNotConfigured(providerID: activeProviderID)) }
        }
        guard provider.isConfigured else {
            return AsyncThrowingStream { $0.finish(throwing: AppError.providerNotConfigured(providerID: provider.id)) }
        }
        return provider.stream(request: request)
    }
}
```

---

## SSEParser

SSE (Server-Sent Events) is used by Anthropic and OpenAI for streaming.

```swift
// SSEParser.swift
// Parses a raw SSE line and returns the data payload if present.

struct SSEParser {
    /// Returns `nil` for comment lines, heartbeats, and empty lines.
    /// Returns the raw JSON string for `data: {...}` lines.
    /// Returns `nil` (signals stream end) for `data: [DONE]`.
    static func extractData(from line: String) -> SSELine {  }
}

enum SSELine {
    case data(String)       // raw JSON string to parse further
    case done               // stream complete
    case skip               // comment or empty line
}
```

Tests for SSEParser are mandatory and must be extensive. See `12_TESTING.md`.

---

## AnthropicProvider (API Key Mode)

```
ID:           "anthropic-api"
displayName:  "Claude (API Key)"
Endpoint:     POST https://api.anthropic.com/v1/messages
Model:        claude-opus-4-5 (default)
Auth:         x-api-key header from Keychain
Streaming:    stream: true → SSE

Request body:
{
  "model": "<model>",
  "max_tokens": 4096,
  "stream": true,
  "system": "<systemPrompt if present>",
  "messages": [
    ...history,
    { "role": "user", "content": "<userPrompt>\n\n<selectedText>" }
  ]
}

SSE token extraction:
  data: {"type":"content_block_delta","delta":{"type":"text_delta","text":"<TOKEN>"}}
  → extract delta.text

Stream end:
  data: {"type":"message_stop"}
  → finish stream
```

---

## AnthropicOAuthProvider (Claude Subscription Mode)

```
ID:           "anthropic-oauth"
displayName:  "Claude (Pro Subscription)"

Prerequisite: Claude Code CLI installed and logged in once.
  install: npm install -g @anthropic-ai/claude-code
  login:   claude login  (stores OAuth token in macOS Keychain)

Architecture:
  AITextTool (Swift) ─stdin/stdout JSON─► sidecar.js (Node.js)
                                              │
                                              ▼
                                    @anthropic-ai/claude-agent-sdk
                                    (uses Keychain OAuth, no API key)

isConfigured check:
  Run: `claude --version` 
  If exit code 0 → configured
  If not found → show "Install Claude Code CLI" in settings

Sidecar protocol (newline-delimited JSON):

  Swift → Node request:
  { "type": "stream", "requestId": "uuid", "prompt": "...", "text": "..." }

  Node → Swift response (one per token):
  { "type": "token", "requestId": "uuid", "token": "Hello" }
  { "type": "done", "requestId": "uuid" }
  { "type": "error", "requestId": "uuid", "message": "..." }

Sidecar management:
  - Spawn once at app launch, keep alive
  - Restart if process dies
  - One sidecar handles all requests sequentially
```

---

## OpenAIProvider (API Key Mode)

```
ID:           "openai"
displayName:  "ChatGPT (API Key)"
Endpoint:     POST https://api.openai.com/v1/chat/completions
Model:        gpt-4o (default)
Auth:         Authorization: Bearer <key>
Streaming:    stream: true → SSE

Request body:
{
  "model": "<model>",
  "stream": true,
  "messages": [
    { "role": "system", "content": "<systemPrompt>" },
    ...history,
    { "role": "user", "content": "<userPrompt>\n\n<selectedText>" }
  ]
}

SSE token extraction:
  data: {"choices":[{"delta":{"content":"<TOKEN>"}}]}
  → extract choices[0].delta.content

Stream end:
  data: [DONE]
  → finish stream
```

---

## OllamaProvider (Local)

```
ID:           "ollama"
displayName:  "Ollama (Local)"
Endpoint:     POST http://localhost:11434/api/chat
Model:        llama3.2 (default, user-configurable)
Auth:         None
Streaming:    stream: true → NDJSON (one JSON object per line)

isConfigured check:
  GET http://localhost:11434/api/tags
  Success → configured (also read available models for settings UI)
  Refused → not running → AppError.ollamaNotRunning

Request body:
{
  "model": "<model>",
  "stream": true,
  "messages": [
    { "role": "system", "content": "<systemPrompt>" },
    ...history,
    { "role": "user", "content": "<prompt>\n\n<selectedText>" }
  ]
}

Token extraction (NDJSON, not SSE):
  {"message":{"role":"assistant","content":"<TOKEN>"},"done":false}
  → extract message.content
  {"done":true}
  → finish stream
```

---

## Prompt Template Filling

Before sending to any provider, fill the prompt template:

```swift
// In AIProviderManager or a PromptFormatter utility
func buildUserMessage(prompt: Prompt, selectedText: String, customInput: String) -> String {
    var result = prompt.template
    result = result.replacingOccurrences(of: "{text}", with: selectedText)
    result = result.replacingOccurrences(of: "{input}", with: customInput)
    return result
}
```

Template variables:
- `{text}` — the selected text (always available)
- `{input}` — user's custom input (for prompts that ask for it)

If template contains no `{text}`, append selectedText after a newline separator.

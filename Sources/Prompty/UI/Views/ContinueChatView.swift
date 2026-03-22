// ContinueChatView.swift
// Prompty
//
// Multi-turn follow-up conversation view.
// Shows message history (user + assistant bubbles) with a follow-up
// text input at bottom and a "Start Over" button.

import SwiftUI

// MARK: - ContinueChatView

struct ContinueChatView: View {
    @Environment(AppState.self) var state

    var body: some View {
        VStack(spacing: 0) {
            conversationList
            Divider()
            inputBar
        }
        .padding(.vertical, 8)
    }

    // MARK: - Conversation List

    private var conversationList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(
                        Array(state.conversationHistory.enumerated()),
                        id: \.offset
                    ) { index, message in
                        MessageBubble(message: message)
                            .id(index)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .onChange(of: state.conversationHistory.count) {
                scrollToBottom(proxy: proxy)
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        @Bindable var bindableState = state
        return VStack(spacing: 8) {
            HStack(spacing: 8) {
                TextField(
                    Strings.ContinueChat.followUpPlaceholder,
                    text: $bindableState.followUpInput
                )
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    submitFollowUp()
                }

                Button(Strings.ContinueChat.send) {
                    submitFollowUp()
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    state.followUpInput
                        .trimmingCharacters(in: .whitespaces)
                        .isEmpty
                    || state.isStreaming
                )
            }

            HStack {
                Button(Strings.ContinueChat.startOver) {
                    state.startOver()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    private func submitFollowUp() {
        let text = state.followUpInput
            .trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        guard !state.isStreaming else { return }

        let userMessage = AIMessage(role: .user, content: text)
        state.appendToConversation(message: userMessage)
        state.followUpInput = ""
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        let lastIndex = state.conversationHistory.count - 1
        guard lastIndex >= 0 else { return }
        withAnimation {
            proxy.scrollTo(lastIndex, anchor: .bottom)
        }
    }
}

// MARK: - MessageBubble

private struct MessageBubble: View {
    let message: AIMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
            Text(isUser
                 ? Strings.ContinueChat.you
                 : Strings.ContinueChat.assistant)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(message.content)
                .font(.body)
                .textSelection(.enabled)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    isUser
                    ? Color.accentColor.opacity(0.15)
                    : Color.secondary.opacity(0.1)
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 10)
                )
        }
        .frame(
            maxWidth: .infinity,
            alignment: isUser ? .trailing : .leading
        )
    }
}

// MARK: - Preview

#Preview {
    let state = PreviewData.makeAppState(mode: .continueChat)
    state.conversationHistory = PreviewData.conversation
    return ContinueChatView()
        .environment(state)
        .frame(width: 480, height: 400)
}

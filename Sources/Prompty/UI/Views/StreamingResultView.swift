// StreamingResultView.swift
// Prompty
//
// Live token display as AI streams response.
// Shows loading shimmer before first token (20K).
// Supports plain/markdown/code render modes (19I).
// Action bar at bottom with keyboard hints.

import SwiftUI

struct StreamingResultView: View {
    @Environment(AppState.self) private var state

    // MARK: - Render Mode

    private var effectiveRenderMode: ResultRenderMode {
        if let sessionOverride = state.panelModeSessionRenderOverride {
            return sessionOverride
        }
        return state.selectedPrompt?.renderMode ?? .markdown
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if state.isWaitingForFirstToken {
                loadingShimmer
            } else {
                resultContent
            }

            Divider()
                .padding(.top, 4)

            ActionBarView(
                resultMode: state.selectedPrompt?.resultMode ?? .copy,
                isStreaming: state.isStreaming,
                tokenUsage: state.lastResponseTokens
            )

            renderModeToggle
        }
    }

    // MARK: - Loading Shimmer (20K)

    private var loadingShimmer: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(
                        maxWidth: index == 2 ? 120 : .infinity,
                        maxHeight: 14
                    )
                    .shimmer()
            }
            Text(Strings.Panel.thinking)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    // MARK: - Result Content (19I)

    private var resultContent: some View {
        ScrollView {
            Group {
                switch effectiveRenderMode {
                case .plain:
                    Text(state.streamingTokens)
                        .font(.body)
                        .textSelection(.enabled)
                case .markdown:
                    Text(LocalizedStringKey(state.streamingTokens))
                        .font(.body)
                        .textSelection(.enabled)
                case .code:
                    Text(state.streamingTokens)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .frame(maxHeight: 300)
    }

    // MARK: - Render Mode Toggle (19I)

    private var renderModeToggle: some View {
        HStack(spacing: 4) {
            if state.isStreaming {
                Button(Strings.Panel.stopStreaming) {
                    state.cancelStreaming()
                }
                .foregroundStyle(.red)
            }

            Spacer()

            ForEach(ResultRenderMode.allCases, id: \.self) { mode in
                Button(action: {
                    state.panelModeSessionRenderOverride = mode
                }) {
                    Text(mode.label)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            effectiveRenderMode == mode
                                ? Color.accentColor.opacity(0.2)
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - ResultRenderMode Label

extension ResultRenderMode {
    var label: String {
        switch self {
        case .plain: return "Aa"
        case .markdown: return "M"
        case .code: return "</>"
        }
    }
}

// MARK: - Shimmer Modifier (20K)

struct ShimmerModifier: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            content
        } else {
            content
                .opacity(isAnimating ? 0.8 : 0.4)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true)
                    ) {
                        isAnimating = true
                    }
                }
        }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

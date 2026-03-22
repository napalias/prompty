// OnboardingView.swift
// Prompty
//
// First-launch onboarding wizard (18D).
// Guides the user through granting Accessibility and Input Monitoring permissions,
// then shows a "Get Started" completion screen.

import SwiftUI

// MARK: - OnboardingViewModel

@Observable
@MainActor
final class OnboardingViewModel {

    // MARK: - Published State

    var accessibilityGranted: Bool = false
    var inputMonitoringGranted: Bool = false
    var currentStep: Int = 1

    // MARK: - UserDefaults Key

    static let hasCompletedOnboardingKey = "hasCompletedOnboarding"

    static var hasCompletedOnboarding: Bool {
        UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
    }

    // MARK: - Polling

    private var timer: Timer?

    func startPolling() {
        checkPermissions()
        timer = Timer.scheduledTimer(
            withTimeInterval: 2.0,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.checkPermissions()
            }
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    private func checkPermissions() {
        accessibilityGranted = AXIsProcessTrusted()
        // Input Monitoring is approximated by checking AX trust;
        // CGEventTap creation is the real gate, tested at hotkey registration
        inputMonitoringGranted = AXIsProcessTrusted()
    }

    // MARK: - Actions

    func openAccessibilitySettings() {
        let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        )
        if let url { NSWorkspace.shared.open(url) }
    }

    func openInputMonitoringSettings() {
        let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
        )
        if let url { NSWorkspace.shared.open(url) }
    }

    func completeOnboarding() {
        stopPolling()
        UserDefaults.standard.set(true, forKey: Self.hasCompletedOnboardingKey)
    }
}

// MARK: - OnboardingView

struct OnboardingView: View {

    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text(Strings.Onboarding.welcomeTitle)
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 32)
                .padding(.bottom, 8)

            Text(Strings.Onboarding.welcomeSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 24)

            Divider()
                .padding(.horizontal, 32)
                .padding(.bottom, 24)

            // Step content
            if viewModel.currentStep == 1 {
                permissionStep(
                    step: 1,
                    title: Strings.Onboarding.accessibilityTitle,
                    description: Strings.Onboarding.accessibilityDescription,
                    icon: "lock.fill",
                    isGranted: viewModel.accessibilityGranted,
                    openAction: viewModel.openAccessibilitySettings
                )
            } else if viewModel.currentStep == 2 {
                permissionStep(
                    step: 2,
                    title: Strings.Onboarding.inputMonitoringTitle,
                    description: Strings.Onboarding.inputMonitoringDescription,
                    icon: "keyboard",
                    isGranted: viewModel.inputMonitoringGranted,
                    openAction: viewModel.openInputMonitoringSettings
                )
            } else {
                completionStep
            }

            Spacer()
        }
        .frame(width: 480, height: 420)
        .onAppear {
            viewModel.startPolling()
        }
        .onDisappear {
            viewModel.stopPolling()
        }
    }

    // MARK: - Permission Step

    @ViewBuilder
    private func permissionStep(
        step: Int,
        title: String,
        description: String,
        icon: String,
        isGranted: Bool,
        openAction: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 16) {
            Text("Step \(step) of 2 — \(title)")
                .font(.headline)

            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
                .padding(.vertical, 8)

            Text(description)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)

            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(isGranted ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(
                    isGranted
                    ? Strings.Onboarding.statusGranted
                    : Strings.Onboarding.statusNotGranted
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)

            Spacer()

            // Action buttons
            HStack {
                Button(Strings.Onboarding.skip) {
                    advanceStep()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                if isGranted {
                    Button(Strings.Onboarding.continueButton) {
                        advanceStep()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(Strings.Onboarding.openSystemSettings) {
                        openAction()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Completion Step

    private var completionStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
                .padding(.top, 16)

            Text(Strings.Onboarding.readyTitle)
                .font(.title2)
                .fontWeight(.semibold)

            Text(Strings.Onboarding.readyDescription)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
                .foregroundStyle(.secondary)

            Spacer()

            Button(Strings.Onboarding.getStarted) {
                viewModel.completeOnboarding()
                // Close the onboarding window
                NSApp.keyWindow?.close()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Navigation

    private func advanceStep() {
        if viewModel.currentStep < 3 {
            viewModel.currentStep += 1
        }
    }
}

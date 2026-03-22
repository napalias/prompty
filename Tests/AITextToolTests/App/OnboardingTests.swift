// OnboardingTests.swift
// AITextToolTests

import Foundation
import Testing
@testable import AITextTool

@MainActor
@Suite("Onboarding", .serialized)
struct OnboardingTests {

    /// Resets the UserDefaults flag before each test to avoid cross-test pollution.
    init() {
        UserDefaults.standard.removeObject(
            forKey: OnboardingViewModel.hasCompletedOnboardingKey
        )
    }

    @Test("Flag is set after completing onboarding")
    func test_onboarding_flagSetAfterCompletion() {
        #expect(OnboardingViewModel.hasCompletedOnboarding == false)

        let viewModel = OnboardingViewModel()
        viewModel.completeOnboarding()

        #expect(OnboardingViewModel.hasCompletedOnboarding == true)

        // Clean up
        UserDefaults.standard.removeObject(
            forKey: OnboardingViewModel.hasCompletedOnboardingKey
        )
    }

    @Test("Flag defaults to false on fresh install")
    func test_onboarding_flagDefaultsFalse() {
        #expect(OnboardingViewModel.hasCompletedOnboarding == false)
    }

    @Test("Starts at step 1")
    func test_onboarding_startsAtStep1() {
        let viewModel = OnboardingViewModel()
        #expect(viewModel.currentStep == 1)
    }

    @Test("Steps can be advanced")
    func test_onboarding_stepsAdvance() {
        let viewModel = OnboardingViewModel()
        #expect(viewModel.currentStep == 1)

        viewModel.currentStep = 2
        #expect(viewModel.currentStep == 2)

        viewModel.currentStep = 3
        #expect(viewModel.currentStep == 3)
    }

    @Test("Polling can be started and stopped without crash")
    func test_onboarding_pollingLifecycle() {
        let viewModel = OnboardingViewModel()
        viewModel.startPolling()
        viewModel.stopPolling()
    }
}

//
//  RootView.swift
//  RollMatch
//
//  Phase coordinator: Splash → (first launch) Onboarding → Main. No auth, no gates.
//

import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var phase: Phase = .splash

    enum Phase { case splash, onboarding, main }

    var body: some View {
        ZStack {
            switch phase {
            case .splash:
                LaunchView {
                    // Splash finished — branch to onboarding or main.
                    withAnimation(.easeInOut(duration: 0.5)) {
                        phase = hasCompletedOnboarding ? .main : .onboarding
                    }
                }
                .transition(.opacity)
            case .onboarding:
                OnboardingView {
                    hasCompletedOnboarding = true
                    withAnimation(.easeInOut(duration: 0.5)) { phase = .main }
                }
                .transition(.opacity)
            case .main:
                MainTabView()
                    .transition(.opacity)
            }
        }
    }
}

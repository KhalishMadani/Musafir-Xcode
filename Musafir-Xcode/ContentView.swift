//
//  ContentView.swift
//  Musafir-Xcode
//
//  Created by Muhammad Khalish Madani on 10/05/26.
//

import SwiftUI

struct ContentView: View {
    /// Not persisted, so onboarding shows on every launch.
    @State private var hasCompletedOnboarding = false

    var body: some View {
        VStack {
            if hasCompletedOnboarding {
                NavigationTab()
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: hasCompletedOnboarding)
//        .padding()
    }
}

#Preview {
    ContentView()
}

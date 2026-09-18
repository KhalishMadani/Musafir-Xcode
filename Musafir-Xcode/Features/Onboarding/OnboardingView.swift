//
//  OnboardingView.swift
//  Musafir-Xcode
//
//  First-launch walkthrough, laid out from the "Nomaden Onboarding" Figma frames.
//

import SwiftUI
import Lottie

struct OnboardingView: View {
    /// Set when the user taps Start. Owned by ContentView and not persisted, so
    /// onboarding shows again on every launch.
    @Binding var hasCompletedOnboarding: Bool
    @AppStorage(Religion.storageKey) private var religion: Religion = .islam
    @State private var page = 0

    private let pages = OnboardingPage.allCases

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 32 / 255, green: 14 / 255, blue: 93 / 255),   // #200E5D
                    Color(red: 130 / 255, green: 61 / 255, blue: 184 / 255), // #823DB8
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Image("onboarding-wordmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 202)
                    .shadow(color: .black.opacity(0.25), radius: 2, y: 4)
                    // Flatten first so the shadow doesn't show through the dimmed letters.
                    .compositingGroup()
                    .opacity(0.85)
                    .padding(.top, 44)

                TabView(selection: $page) {
                    ForEach(pages) { item in
                        pageContent(item)
                            .tag(item.rawValue)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack {
                    pageIndicator
                    Spacer()
                    nextButton
                }
                .padding(.leading, 34)
                .padding(.trailing, 31)
                .padding(.bottom, 44)
            }
        }
    }

    // MARK: - Pages

    /// Every page shares the same illustration band and message slot, so nothing
    /// jumps when swiping between pages.
    private func pageContent(_ item: OnboardingPage) -> some View {
        VStack(spacing: 0) {
            illustration(item)
                .frame(maxWidth: .infinity, maxHeight: 414)

            Text(item.message)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
                // Room for three lines, top-aligned so short and long messages start level.
                .frame(maxWidth: .infinity, minHeight: 80, alignment: .top)
                .padding(.top, 32)

            Spacer(minLength: 0)
        }
    }

    /// Centred in the band, which shrinks on shorter screens.
    @ViewBuilder
    private func illustration(_ item: OnboardingPage) -> some View {
        switch item {
        case .journey:
            LottieAnimation(name: "onboarding-walking")
                .frame(maxWidth: 317)
        case .nearest:
            LottieAnimation(name: "onboarding-location")
                .frame(maxWidth: 352, maxHeight: 272)
        case .religion:
            religionPicker
        }
    }

    /// Frosted card holding the wheel, so the religion is chosen before the map loads.
    private var religionPicker: some View {
        ReligionWheel(selection: $religion)
            .frame(width: 307, height: 285)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26)
                            .strokeBorder(
                                LinearGradient(
                                    stops: [
                                        .init(color: .white.opacity(0.4), location: 0),
                                        .init(color: .white.opacity(0.01), location: 0.4),
                                        .init(color: .white.opacity(0.01), location: 0.57),
                                        .init(color: .white.opacity(0.1), location: 1),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.7
                            )
                    )
            )
    }

    // MARK: - Controls

    /// Bars fill in as the user advances, matching the mockup.
    private var pageIndicator: some View {
        HStack(spacing: 3) {
            ForEach(pages) { item in
                Capsule()
                    .fill(.white.opacity(item.rawValue <= page ? 1 : 0.5))
                    .frame(width: 25, height: 7)
            }
        }
        .animation(.easeInOut, value: page)
    }

    private var isLastPage: Bool { page == pages.count - 1 }

    private var nextButton: some View {
        Button {
            if isLastPage {
                hasCompletedOnboarding = true
            } else {
                withAnimation { page += 1 }
            }
        } label: {
            HStack(spacing: 6) {
                Text(isLastPage ? "Start" : "Next")
                    .font(.system(size: 20, weight: .bold))
                Image(systemName: "chevron.forward.2")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(Color(white: 0.1))
            .frame(width: 145, height: 45)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

private enum OnboardingPage: Int, CaseIterable, Identifiable {
    case journey, nearest, religion

    var id: Int { rawValue }

    var message: String {
        switch self {
        case .journey: "Every journey deserves a peaceful place to pause and pray."
        case .nearest: "Help you find the nearest place to pray."
        case .religion: "Choose your religion from the 5 major faiths in Indonesia."
        }
    }
}

/// Looping dotLottie animation bundled in Features/Onboarding/Animations.
private struct LottieAnimation: View {
    let name: String

    var body: some View {
        LottieView {
            try await DotLottieFile.named(name)
        }
        .looping()
        .resizable()
        .scaledToFit()
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}

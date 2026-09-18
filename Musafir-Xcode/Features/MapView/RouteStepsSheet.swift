//
//  RouteStepsSheet.swift
//  Musafir-Xcode
//
//  Written directions for the route drawn on the map. MapKit exposes no turn-by-turn
//  guidance to third-party apps, so the steps are listed rather than spoken.
//

import SwiftUI
import MapKit

struct RouteStepsSheet: View {
    let route: MKRoute
    let destinationName: String
    /// Step the user is currently travelling toward, or nil when the route is only
    /// being previewed. Marks the live row so a long list stays readable mid-walk.
    let currentStepIndex: Int?

    private let distanceFormatter: MKDistanceFormatter = {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        return formatter
    }()

    var body: some View {
        NavigationStack {
            List {
                // MapKit's first step is an empty "start" placeholder.
                ForEach(Array(route.steps.enumerated()), id: \.offset) { index, step in
                    if !step.instructions.isEmpty {
                        let isCurrent = index == currentStepIndex
                        let isDone = currentStepIndex.map { index < $0 } ?? false

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.instructions)
                                    .font(.system(size: 16, weight: isCurrent ? .bold : .regular))

                                Text(distanceFormatter.string(fromDistance: step.distance))
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer(minLength: 0)

                            if isDone {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                        .foregroundStyle(isDone ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
                        .listRowBackground(
                            isCurrent ? MusafirTheme.accent.opacity(0.12) : Color.clear
                        )
                    }
                }
            }
            .navigationTitle(destinationName)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

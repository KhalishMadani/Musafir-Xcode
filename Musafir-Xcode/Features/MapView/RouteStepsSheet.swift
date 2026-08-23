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

    private let distanceFormatter: MKDistanceFormatter = {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        return formatter
    }()

    var body: some View {
        NavigationStack {
            List {
                // MapKit's first step is an empty "start" placeholder.
                ForEach(Array(route.steps.enumerated()), id: \.offset) { _, step in
                    if !step.instructions.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.instructions)
                                .font(.system(size: 16))

                            Text(distanceFormatter.string(fromDistance: step.distance))
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
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

//
//  RouteProgress.swift
//  Musafir-Xcode
//
//  Where the user sits along a route. MapKit hands third-party apps a static
//  MKRoute and nothing else, so the follow-along part — which step is live, how
//  far is left, whether the user has wandered off — is worked out here.
//

import Foundation
import MapKit

/// A single snapshot of the user's position along a route.
struct RouteProgress {
    /// Index into `MKRoute.steps` of the maneuver being travelled toward.
    let stepIndex: Int
    /// Metres from the user to the end of that step, i.e. to the next turn.
    let distanceToStepEnd: CLLocationDistance
    /// Metres from the user to the nearest point of the route line. Large values
    /// mean the user is no longer on the route.
    let offRouteDistance: CLLocationDistance
    /// Metres left to the destination, measured along the route rather than
    /// straight-line.
    let remainingDistance: CLLocationDistance
    /// Seconds left, scaled from the route's original estimate.
    let remainingTime: TimeInterval
    /// The route line from the user's projected position onward, so the part
    /// already walked can be dropped from the map.
    let remainingPolyline: MKPolyline?
}

/// Pre-chews a route's geometry once so each location fix costs one linear scan
/// instead of re-flattening every polyline.
struct RouteTracker {
    /// Every vertex of the route line, in projected map space.
    private let points: [MKMapPoint]
    /// Metres travelled at each vertex, so a projection converts to a distance
    /// along the route with one interpolation.
    private let cumulative: [CLLocationDistance]
    /// Metres travelled at the end of each step, for bucketing the user into one.
    private let stepEnds: [CLLocationDistance]
    private let totalDistance: CLLocationDistance
    private let expectedTravelTime: TimeInterval

    init(route: MKRoute) {
        let vertices = Self.vertices(of: route.polyline)
        points = vertices

        var running: CLLocationDistance = 0
        var distances: [CLLocationDistance] = [0]
        distances.reserveCapacity(vertices.count)
        if vertices.count > 1 {
            for index in 1..<vertices.count {
                running += vertices[index - 1].distance(to: vertices[index])
                distances.append(running)
            }
        }
        cumulative = distances
        totalDistance = running

        // Step boundaries are measured off the step polylines rather than
        // `step.distance`, so they land on the same scale as `cumulative`.
        var walked: CLLocationDistance = 0
        stepEnds = route.steps.map { step in
            walked += Self.length(of: step.polyline)
            return walked
        }

        expectedTravelTime = route.expectedTravelTime
    }

    /// Projects `location` onto the route. Nil only for a degenerate route line.
    func progress(for location: CLLocation) -> RouteProgress? {
        guard points.count >= 2 else { return nil }

        let user = MKMapPoint(location.coordinate)
        var bestSegment = 0
        var bestFraction = 0.0
        var bestSquaredDistance = Double.greatestFiniteMagnitude

        // Nearest point on each segment, keeping the closest. Map space is planar,
        // so this is ordinary point-to-segment projection.
        for index in 0..<(points.count - 1) {
            let start = points[index]
            let end = points[index + 1]
            let dx = end.x - start.x
            let dy = end.y - start.y
            let segmentSquared = dx * dx + dy * dy

            var fraction = 0.0
            if segmentSquared > 0 {
                fraction = ((user.x - start.x) * dx + (user.y - start.y) * dy) / segmentSquared
                fraction = min(max(fraction, 0), 1)
            }

            let offsetX = user.x - (start.x + dx * fraction)
            let offsetY = user.y - (start.y + dy * fraction)
            let squaredDistance = offsetX * offsetX + offsetY * offsetY

            if squaredDistance < bestSquaredDistance {
                bestSquaredDistance = squaredDistance
                bestSegment = index
                bestFraction = fraction
            }
        }

        let metresPerPoint = MKMetersPerMapPointAtLatitude(location.coordinate.latitude)
        let offRouteDistance = bestSquaredDistance.squareRoot() * metresPerPoint

        let segmentStart = cumulative[bestSegment]
        let segmentEnd = cumulative[bestSegment + 1]
        let travelled = segmentStart + (segmentEnd - segmentStart) * bestFraction
        let remainingDistance = max(totalDistance - travelled, 0)

        // The first step whose end the user has not yet passed is the live one.
        // A metre of slack keeps a fix sitting exactly on a boundary from
        // flickering between two steps.
        let stepIndex = stepEnds.firstIndex { $0 > travelled + 1 } ?? max(stepEnds.count - 1, 0)
        let distanceToStepEnd = stepIndex < stepEnds.count
            ? max(stepEnds[stepIndex] - travelled, 0)
            : remainingDistance

        return RouteProgress(
            stepIndex: stepIndex,
            distanceToStepEnd: distanceToStepEnd,
            offRouteDistance: offRouteDistance,
            remainingDistance: remainingDistance,
            remainingTime: totalDistance > 0
                ? expectedTravelTime * (remainingDistance / totalDistance)
                : 0,
            remainingPolyline: tail(from: bestSegment, fraction: bestFraction)
        )
    }

    /// The route line from the projected position to the destination.
    private func tail(from segment: Int, fraction: Double) -> MKPolyline? {
        let start = points[segment]
        let end = points[segment + 1]
        let projected = MKMapPoint(
            x: start.x + (end.x - start.x) * fraction,
            y: start.y + (end.y - start.y) * fraction
        )

        var remaining = [projected]
        remaining.append(contentsOf: points[(segment + 1)...])
        guard remaining.count >= 2 else { return nil }
        return MKPolyline(points: remaining, count: remaining.count)
    }

    private static func vertices(of polyline: MKPolyline) -> [MKMapPoint] {
        Array(UnsafeBufferPointer(start: polyline.points(), count: polyline.pointCount))
    }

    private static func length(of polyline: MKPolyline) -> CLLocationDistance {
        let vertices = Self.vertices(of: polyline)
        guard vertices.count > 1 else { return 0 }
        return (1..<vertices.count).reduce(into: 0) { total, index in
            total += vertices[index - 1].distance(to: vertices[index])
        }
    }
}

//
//  MapModel.swift
//  Musafir-Xcode
//
//  Camera, pins, routing and selection shared by the Explore and Search tabs so
//  switching between them keeps the same map on screen, the way Apple Maps does.
//

import Foundation
import SwiftUI
import MapKit

/// A prayer space plus its distance from the user, worked out once when the results
/// or the user's location change rather than on every redraw.
struct RankedPlace: Identifiable, Hashable {
    let item: MKMapItem
    let distance: CLLocationDistance?

    var id: MKMapItem { item }

    var distanceText: String? {
        guard let distance else { return nil }
        if distance < 1000 {
            return "\(Int(distance.rounded())) m away"
        }
        return String(format: "%.1f km away", distance / 1000)
    }
}

@Observable
final class MapModel: NSObject, CLLocationManagerDelegate {
    /// What produced the pins currently on the map. Nearby results are capped to
    /// `nearbyRadius`; typed results are shown wherever they landed, like Apple Maps.
    enum SearchMode {
        case nearby
        case query
    }

    /// Which map is on screen. Only the active one drives the camera, so the two
    /// tabs don't write competing regions into the shared position.
    enum MapTab {
        case explore
        case search
    }

    /// Camera shared by every map on screen; both tabs bind to this.
    var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    /// Prayer spaces currently pinned on the map.
    var places: [MKMapItem] = []
    /// Cards for the list, nearest first. Rebuilt only when the inputs change.
    private(set) var cards: [RankedPlace] = []
    /// Place highlighted by the card list and shown in the detail sheet.
    var selectedItem: MKMapItem?
    /// Drives the detail sheet presented from a card tap.
    var isShowingDetail = false
    /// True only while the camera is animating back to the user's location.
    var isRecentering = false
    /// Text typed into the search tab's field.
    var searchQuery = ""
    /// True while an MKLocalSearch is in flight.
    var isSearching = false
    private(set) var mode: SearchMode = .nearby

    /// Tab currently showing a map. Gates camera writes to the visible one.
    var activeTab: MapTab = .explore

    // MARK: - Routing

    /// Route drawn on the map, computed in-app rather than handed to Apple Maps.
    var route: MKRoute?
    /// Destination the route leads to, kept for recomputing on a transport change.
    private(set) var routeDestination: MKMapItem?
    var isRouting = false
    /// Drives the written-directions sheet opened from the route banner.
    var isShowingSteps = false
    var routeError: String?
    var transportType: MKDirectionsTransportType = .walking

    // MARK: - Navigation

    /// True while the map is following the user along the route. The route can be
    /// on screen without this being set: drawing the line and walking it are two
    /// separate acts, the way Apple Maps separates the preview from "Go".
    private(set) var isNavigating = false
    /// Where the user is along the route, recomputed on every fix.
    private(set) var progress: RouteProgress?
    /// Set once the destination is reached, so the banner can say so instead of
    /// silently vanishing.
    private(set) var hasArrived = false
    /// The route's geometry, chewed once per route rather than per fix.
    private var tracker: RouteTracker?
    /// Consecutive fixes found too far from the line. A single bad fix in a street
    /// canyon shouldn't trigger a reroute.
    private var offRouteFixes = 0
    /// When the last automatic reroute fired, to stop a bad GPS patch from
    /// requesting directions over and over.
    private var lastRerouteAt: Date?
    /// Compass heading, used to point the camera while the user is standing still
    /// and `course` has nothing to report.
    private var compassHeading: CLLocationDirection?
    /// Heading the camera was last pointed at, so small compass jitter doesn't
    /// re-animate the camera many times a second.
    private var cameraHeading: CLLocationDirection?

    /// Metres from the route line before the user counts as off it.
    private let offRouteThreshold: CLLocationDistance = 50
    /// How many consecutive off-route fixes force a reroute.
    private let offRouteFixesBeforeReroute = 3
    /// Minimum gap between automatic reroutes.
    private let rerouteCooldown: TimeInterval = 10
    /// Metres from the destination that count as having arrived.
    private let arrivalRadius: CLLocationDistance = 30
    /// Below this speed the course reading is noise, so the compass drives the camera.
    private let stationarySpeed: CLLocationSpeed = 0.5

    /// Region the camera is showing right now, refreshed when a pan or zoom ends.
    var visibleRegion: MKCoordinateRegion?
    /// Region the pins on screen were searched in. Comparing it against
    /// `visibleRegion` is what decides whether "Search here" is offered.
    private var searchedRegion: MKCoordinateRegion?

    /// Cards only list prayer spaces within this distance of the user.
    let nearbyRadius: CLLocationDistance = 10_000

    /// Latest fix, pushed in by the delegate. Reading `CLLocationManager.location`
    /// on every redraw is what made the card list crawl.
    private(set) var userLocation: CLLocation?

    let manager = CLLocationManager()

    private var currentSearch: MKLocalSearch?
    private var currentDirections: MKDirections?
    private var queryTask: Task<Void, Never>?
    /// The camera follows the user only for the first fix; after that the user owns it.
    private var hasCenteredOnUser = false
    /// A nearby search asked for before any fix arrived, run as soon as one does.
    private var needsNearbySearch = false
    /// Where the nearby results were searched from, so a real move refreshes them.
    private var lastNearbySearchCenter: CLLocation?

    /// Religion picked in ConfigureView. Read straight from the same store
    /// `@AppStorage` writes to, so the model never holds a stale copy.
    var religion: Religion {
        Religion(rawValue: UserDefaults.standard.string(forKey: Religion.storageKey) ?? "")
            ?? .islam
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        // Without a filter every small fix rebuilds the card list for no visible gain.
        manager.distanceFilter = 50
    }

    /// True once the camera has drifted far enough from the searched region that the
    /// pins no longer describe what the user is looking at.
    var canSearchHere: Bool {
        guard let visible = visibleRegion, let searched = searchedRegion else { return false }

        let drift = CLLocation(latitude: visible.center.latitude, longitude: visible.center.longitude)
            .distance(from: CLLocation(latitude: searched.center.latitude, longitude: searched.center.longitude))
        let searchedSpan = searched.span.latitudeDelta * metersPerDegreeLatitude

        // Panned more than a third of the searched area away, or zoomed out well past it.
        return drift > searchedSpan * 0.35
            || visible.span.latitudeDelta > searched.span.latitudeDelta * 1.5
    }

    private let metersPerDegreeLatitude: CLLocationDistance = 111_000

    // MARK: - Location

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location

        // While navigating the cards are off screen and the nearby results are
        // frozen; the fix exists to move the camera and advance the route.
        if isNavigating {
            updateProgress(for: location)
            followUser()
            return
        }

        rebuildCards()

        // First fix: frame the user's surroundings with a concrete region. Leaving the
        // camera on `.userLocation(fallback: .automatic)` lets a freshly appearing map
        // — the search tab's — fall back to the whole-world view.
        if !hasCenteredOnUser {
            hasCenteredOnUser = true
            cameraPosition = .region(region(around: location.coordinate, meters: 3_000))
        }

        if needsNearbySearch {
            needsNearbySearch = false
            searchNearby()
            return
        }

        // The user has travelled far enough that the nearby results describe where
        // they were, not where they are — and the 10 km card filter would empty out.
        if mode == .nearby, let last = lastNearbySearchCenter,
           location.distance(from: last) > refreshDistance {
            searchNearby()
        }
    }

    /// How far the user must move before the nearby results are searched again.
    private let refreshDistance: CLLocationDistance = 2_000

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }
        compassHeading = newHeading.trueHeading

        // The compass only owns the camera when the user isn't moving; otherwise
        // `course` is steadier. Turning on the spot still turns the map.
        guard isNavigating,
              let userLocation,
              userLocation.speed <= stationarySpeed else { return }

        if let cameraHeading,
           abs(newHeading.trueHeading - cameraHeading) < 8 { return }
        followUser()
    }

    // MARK: - Distance

    func distance(to item: MKMapItem) -> CLLocationDistance? {
        guard let origin = userLocation else { return nil }
        let coordinate = item.location.coordinate
        return origin.distance(
            from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        )
    }

    func addressText(for item: MKMapItem) -> String {
        item.addressRepresentations?.fullAddress(includingRegion: false, singleLine: true)
            ?? religion.placeholderName
    }

    /// Sorts by distance, and in nearby mode drops anything past the card radius.
    private func rebuildCards() {
        var ranked = places.map { RankedPlace(item: $0, distance: distance(to: $0)) }
        ranked.sort { ($0.distance ?? .infinity) < ($1.distance ?? .infinity) }

        if mode == .nearby, userLocation != nil {
            ranked = ranked.filter { ($0.distance ?? .infinity) <= nearbyRadius }
        }
        cards = ranked
    }

    // MARK: - Selection

    /// Opens the detail sheet for a place. Card taps zoom the camera onto it; pin
    /// taps skip the zoom because the user is already looking at that spot.
    func select(_ item: MKMapItem, zoom: Bool = true) {
        selectedItem = item
        isShowingDetail = true
        guard zoom else { return }
        withAnimation(.easeInOut(duration: 0.4)) {
            cameraPosition = .region(region(around: item.location.coordinate, meters: 500))
        }
    }

    /// Drops the selection once the sheet closes. Without this the tapped pin stays
    /// selected, and tapping it again wouldn't change the binding or reopen the sheet.
    func clearSelection() {
        selectedItem = nil
        isShowingDetail = false
    }

    // MARK: - Search

    /// Animates back to the user and refreshes the nearby prayer spaces. The filled
    /// icon is held for the animation; `onMapCameraChange` clears it, with a timeout
    /// in case the camera never moves.
    func recenterOnUser() {
        isRecentering = true
        selectedItem = nil
        searchQuery = ""

        withAnimation(.easeInOut(duration: 0.4)) {
            if let userLocation {
                cameraPosition = .region(region(around: userLocation.coordinate, meters: 3_000))
            } else {
                cameraPosition = .userLocation(fallback: .automatic)
            }
        }
        searchNearby()

        Task {
            try? await Task.sleep(for: .seconds(1))
            isRecentering = false
        }
    }

    /// Prayer spaces around the user, searched over the full card radius so the
    /// nearest ones outside walking distance still make the list. Before the first
    /// fix the search is deferred to the delegate rather than polled for.
    func searchNearby() {
        guard let userLocation else {
            needsNearbySearch = true
            return
        }
        lastNearbySearchCenter = userLocation
        run(
            query: religion.searchQuery,
            region: region(around: userLocation.coordinate, meters: nearbyRadius * 2),
            mode: .nearby
        )
    }

    /// Runs the typed query after a short pause, so results follow the keystrokes
    /// without firing a request per character.
    func queryChanged() {
        queryTask?.cancel()
        queryTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            self?.searchByName()
        }
    }

    /// Search-tab query. The text is passed through as typed — Apple Maps searches
    /// what you wrote, not what the app thinks you meant. Results replace the pins on
    /// the shared map, so the map the user was already looking at simply updates.
    func searchByName() {
        queryTask?.cancel()
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchNearby()
            return
        }
        run(query: trimmed, region: searchRegion(), mode: .query)
    }

    /// "Search here": re-runs the active query over the region on screen.
    func searchVisibleRegion() {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        run(
            query: trimmed.isEmpty ? religion.searchQuery : trimmed,
            region: visibleRegion ?? searchRegion(),
            mode: trimmed.isEmpty ? .nearby : .query
        )
    }

    /// Clears pins that belong to a religion the user just switched away from.
    func reset() {
        queryTask?.cancel()
        currentSearch?.cancel()
        places = []
        cards = []
        selectedItem = nil
        isShowingDetail = false
        searchedRegion = nil
        lastNearbySearchCenter = nil
        clearRoute()
    }

    /// Where a typed search should look: the area on screen, falling back to the
    /// user's surroundings before the camera has reported a region.
    private func searchRegion() -> MKCoordinateRegion? {
        if let visibleRegion { return visibleRegion }
        guard let userLocation else { return nil }
        return region(around: userLocation.coordinate, meters: nearbyRadius * 2)
    }

    private func region(around coordinate: CLLocationCoordinate2D, meters: CLLocationDistance) -> MKCoordinateRegion {
        MKCoordinateRegion(center: coordinate, latitudinalMeters: meters, longitudinalMeters: meters)
    }

    private func run(query: String, region: MKCoordinateRegion?, mode: SearchMode) {
        // A newer search supersedes whatever is still in flight.
        currentSearch?.cancel()

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        if let region {
            request.region = region
        }

        self.mode = mode
        searchedRegion = region
        isSearching = true

        let search = MKLocalSearch(request: request)
        currentSearch = search
        search.start { [weak self] response, _ in
            guard let self, self.currentSearch === search else { return }
            self.isSearching = false
            self.currentSearch = nil
            // A cancelled or failed search leaves the existing pins alone.
            guard let response else { return }
            self.places = response.mapItems
            self.rebuildCards()
        }
    }

    // MARK: - Directions

    /// Draws the route inside the app instead of launching Apple Maps. MapKit has no
    /// public turn-by-turn guidance, so this is the line, the ETA and the written steps.
    func startDirections(to item: MKMapItem) {
        stopNavigation()
        hasArrived = false
        routeDestination = item
        requestRoute()
    }

    /// Recomputes the current route after the user switches walking/driving.
    func setTransportType(_ type: MKDirectionsTransportType) {
        guard transportType != type else { return }
        transportType = type
        requestRoute()
    }

    func clearRoute() {
        stopNavigation()
        currentDirections?.cancel()
        currentDirections = nil
        route = nil
        routeDestination = nil
        tracker = nil
        hasArrived = false
        isRouting = false
        isShowingSteps = false
        routeError = nil
    }

    private func requestRoute() {
        guard let destination = routeDestination else { return }
        currentDirections?.cancel()

        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = destination
        request.transportType = transportType

        isRouting = true
        routeError = nil

        let directions = MKDirections(request: request)
        currentDirections = directions
        directions.calculate { [weak self] response, error in
            guard let self, self.currentDirections === directions else { return }
            self.isRouting = false
            self.currentDirections = nil

            guard let route = response?.routes.first else {
                self.routeError = error?.localizedDescription ?? "No route found"
                return
            }

            self.route = route
            self.tracker = RouteTracker(route: route)

            // A reroute must not throw the camera back to a whole-route overview;
            // the user is mid-journey and wants to keep looking ahead.
            guard !self.isNavigating else {
                if let userLocation = self.userLocation {
                    self.updateProgress(for: userLocation)
                }
                return
            }

            withAnimation(.easeInOut(duration: 0.4)) {
                self.cameraPosition = .rect(self.paddedRect(for: route))
            }
        }
    }

    // MARK: - Navigation

    /// Starts following the route: tight location updates, compass on, and the
    /// camera locked ahead of the user.
    func startNavigation() {
        guard route != nil, !isNavigating else { return }
        isNavigating = true
        hasArrived = false
        offRouteFixes = 0
        lastRerouteAt = nil
        selectedItem = nil
        isShowingDetail = false

        // Coarse fixes every 50 m are enough to rank cards but far too blunt to
        // walk a route with.
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = kCLDistanceFilterNone
        manager.pausesLocationUpdatesAutomatically = false
        manager.startUpdatingHeading()

        if let userLocation {
            updateProgress(for: userLocation)
        }
        followUser()
    }

    /// Stops following and hands the camera back to the user. The route itself is
    /// left on the map; `clearRoute()` is what removes it.
    func stopNavigation() {
        guard isNavigating else { return }
        isNavigating = false
        progress = nil
        offRouteFixes = 0
        compassHeading = nil
        cameraHeading = nil

        manager.stopUpdatingHeading()
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 50
        manager.pausesLocationUpdatesAutomatically = true
    }

    /// Advances the route for a new fix: arrival first, then off-route detection.
    private func updateProgress(for location: CLLocation) {
        guard let tracker, let next = tracker.progress(for: location) else { return }
        progress = next

        if let destination = routeDestination {
            let coordinate = destination.location.coordinate
            let straightLine = location.distance(
                from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            )
            if straightLine <= arrivalRadius || next.remainingDistance <= arrivalRadius {
                arrive()
                return
            }
        }

        guard next.offRouteDistance > offRouteThreshold else {
            offRouteFixes = 0
            return
        }

        offRouteFixes += 1
        guard offRouteFixes >= offRouteFixesBeforeReroute else { return }

        let now = Date()
        if let lastRerouteAt, now.timeIntervalSince(lastRerouteAt) < rerouteCooldown { return }
        lastRerouteAt = now
        offRouteFixes = 0
        requestRoute()
    }

    private func arrive() {
        hasArrived = true
        stopNavigation()
        progress = nil
    }

    /// Points the camera down the user's direction of travel. Course is used while
    /// moving and the compass while standing still, because a stationary fix
    /// reports no course at all.
    private func followUser() {
        guard let userLocation else { return }

        let course = userLocation.course
        let bearing: CLLocationDirection
        if userLocation.speed > stationarySpeed,
           userLocation.courseAccuracy >= 0,
           course >= 0 {
            bearing = course
        } else if let compassHeading {
            bearing = compassHeading
        } else {
            bearing = cameraHeading ?? 0
        }

        cameraHeading = bearing

        withAnimation(.linear(duration: 1)) {
            cameraPosition = .camera(
                MapCamera(
                    centerCoordinate: userLocation.coordinate,
                    distance: 500,
                    heading: bearing,
                    pitch: 55
                )
            )
        }
    }

    // MARK: - Route text

    /// The maneuver the user is heading toward. MapKit's first step is an empty
    /// "start" placeholder, so empty instructions are skipped forward.
    var currentInstruction: String? {
        guard let route, let progress else { return nil }
        let steps = route.steps
        guard progress.stepIndex < steps.count else { return nil }
        for index in progress.stepIndex..<steps.count where !steps[index].instructions.isEmpty {
            return steps[index].instructions
        }
        return nil
    }

    /// Distance to the next turn, e.g. "in 120 m".
    var distanceToNextTurn: String? {
        guard let progress else { return nil }
        return MapModel.distanceFormatter.string(fromDistance: progress.distanceToStepEnd)
    }

    /// Live "8 min · 650 m" while navigating, falling back to the route's original
    /// estimate before the first fix lands.
    var remainingSummary: String? {
        guard let progress else { return routeSummary }
        return MapModel.summary(
            time: progress.remainingTime,
            distance: progress.remainingDistance
        )
    }

    /// The line drawn on the map: the untravelled part while navigating, the whole
    /// route otherwise.
    var routeOverlay: MKPolyline? {
        if isNavigating, let remaining = progress?.remainingPolyline {
            return remaining
        }
        return route?.polyline
    }

    private static let distanceFormatter: MKDistanceFormatter = {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        return formatter
    }()

    private static let timeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    private static func summary(time: TimeInterval, distance: CLLocationDistance) -> String {
        let eta = timeFormatter.string(from: max(time, 60)) ?? ""
        return "\(eta) · \(distanceFormatter.string(fromDistance: distance))"
    }

    /// The route's bounding box with room left around it for the cards and buttons.
    private func paddedRect(for route: MKRoute) -> MKMapRect {
        let rect = route.polyline.boundingMapRect
        return rect.insetBy(dx: -rect.width * 0.25, dy: -rect.height * 0.35)
    }

    var routeSummary: String? {
        guard let route else { return nil }
        return MapModel.summary(time: route.expectedTravelTime, distance: route.distance)
    }
}

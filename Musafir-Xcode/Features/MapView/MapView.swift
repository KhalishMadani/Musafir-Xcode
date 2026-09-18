//
//  MapView.swift
//  Musafir-Xcode
//
//  Created by Muhammad Khalish Madani on 11/05/26.
//

import SwiftUI
import MapKit

struct MapView: View {
    @Bindable var model: MapModel
    /// Which tab this map belongs to. Both tabs render a map and share one camera,
    /// so only the one on screen is allowed to write camera state back.
    let tab: MapModel.MapTab
    @AppStorage(Religion.storageKey) private var religion: Religion = .islam

    /// Height of the strip at the bottom of the map that carries the Apple logo
    /// and "Legal" link. The map is drawn this much taller than its container so
    /// the strip falls outside the clipped bounds.
    private let attributionInset: CGFloat = 44

    private var isActive: Bool { model.activeTab == tab }

    var body: some View {
        GeometryReader { geometry in
            // `selection` is what makes the pins tappable: MapKit writes the tagged
            // item back into `model.selectedItem`, and `onChange` opens the sheet.
            Map(position: $model.cameraPosition, selection: $model.selectedItem) {
                UserAnnotation()

                if let overlay = model.routeOverlay {
                    MapPolyline(overlay)
                        .stroke(
                            MusafirTheme.accent,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                        )
                }

                ForEach(model.places, id: \.self) { item in
                    Marker(
                        item.name ?? religion.placeholderName,
                        systemImage: religion.markerSymbol,
                        coordinate: item.location.coordinate
                    )
                    .tint(item == model.selectedItem ? MusafirTheme.accent : .red)
                    .tag(item)
                }
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                // The off-screen tab's map also reports camera changes; letting it
                // write would have the two maps chasing each other's regions.
                guard isActive, !model.isNavigating else { return }
                model.isRecentering = false
                model.visibleRegion = context.region
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height + attributionInset
            )
        }
        .clipped()
        .ignoresSafeArea()
        .safeAreaInset(edge: .bottom) {
            // Recenter button sits directly above the prayer-space cards, and the
            // whole stack rides above the tab bar via the bottom safe-area inset.
            VStack(alignment: .trailing, spacing: 12) {
                if model.canSearchHere && model.route == nil {
                    searchHereButton
                        .frame(maxWidth: .infinity)
                        .transition(.opacity)
                }

                if !model.isNavigating {
                    recenterButton
                        .padding(.trailing, 20)
                }

                if model.isNavigating {
                    navigationBanner
                        .padding(.horizontal, MusafirTheme.cardSpacing)
                        .onTapGesture { model.isShowingSteps = true }
                } else if model.hasArrived {
                    arrivalBanner
                        .padding(.horizontal, MusafirTheme.cardSpacing)
                } else if model.route != nil || model.isRouting || model.routeError != nil {
                    VStack(spacing: 10) {
                        if model.route != nil {
                            startButton
                        }

                        routeBanner
                            .onTapGesture {
                                guard model.route != nil else { return }
                                model.isShowingSteps = true
                            }
                    }
                    .padding(.horizontal, MusafirTheme.cardSpacing)
                } else if !model.cards.isEmpty {
                    nearbyList
                } else if model.mode == .query && !model.isSearching {
                    noResultsLabel
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8)
            .animation(.easeInOut(duration: 0.2), value: model.canSearchHere)
            .animation(.easeInOut(duration: 0.25), value: model.isNavigating)
        }
        .onAppear {
            model.activeTab = tab
            model.requestAuthorization()
            if model.places.isEmpty {
                model.searchNearby()
            }
        }
        .onChange(of: model.selectedItem) { _, item in
            // Fires for pin taps as well as card taps; the card already opened the
            // sheet, so re-selecting the same item here is a no-op.
            guard let item else { return }
            model.select(item, zoom: false)
        }
        .onChange(of: religion) {
            // Stale pins belong to the previous religion; drop them before re-searching.
            model.reset()
            model.searchNearby()
        }
    }

    /// Apple Maps' "Search here": re-runs the current query over the area on screen
    /// once the user has panned away from where the pins came from.
    private var searchHereButton: some View {
        Button {
            model.searchVisibleRegion()
        } label: {
            Label("Search here", systemImage: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.primary)
                .padding(.horizontal, 18)
                .frame(height: 40)
                .glassEffect(.regular.interactive(), in: .capsule)
        }
        .buttonStyle(.plain)
    }

    private var noResultsLabel: some View {
        Text("No results found")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 18)
            .frame(height: 40)
            .glassEffect(.regular, in: .capsule)
    }

    private var recenterButton: some View {
        Button {
            model.recenterOnUser()
        } label: {
            Image(systemName: model.isRecentering ? "location.fill" : "location")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(model.isRecentering ? MusafirTheme.accent : Color.primary)
                .frame(
                    width: MusafirTheme.recenterButtonSize,
                    height: MusafirTheme.recenterButtonSize
                )
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .buttonStyle(.plain)
    }

    /// Replaces the card list while a route is on the map: ETA, distance, the
    /// walk/drive toggle and a way out.
    private var routeBanner: some View {
        HStack(spacing: 12) {
            if model.isRouting {
                ProgressView()
                Text("Finding route…")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MusafirTheme.cardLabel)
            } else if let error = model.routeError {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(MusafirTheme.cardLabel)
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(MusafirTheme.cardLabel)
                    .lineLimit(2)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.routeSummary ?? "")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(MusafirTheme.cardLabel)

                    Text(model.routeDestination?.name ?? religion.placeholderName)
                        .font(.system(size: 13))
                        .foregroundStyle(MusafirTheme.cardSecondaryLabel)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                transportButton(.walking, symbol: "figure.walk")
                transportButton(.automobile, symbol: "car.fill")
            }

            Spacer(minLength: 0)

            Button {
                model.clearRoute()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(MusafirTheme.cardLabel)
                    .frame(width: 32, height: 32)
                    .background(MusafirTheme.cardStroke.opacity(0.2), in: .circle)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .frame(height: MusafirTheme.cardHeight)
        .background(
            MusafirTheme.cardFill,
            in: RoundedRectangle(cornerRadius: MusafirTheme.cardCornerRadius)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MusafirTheme.cardCornerRadius)
                .stroke(MusafirTheme.cardStroke, lineWidth: 1)
        )
    }

    private func transportButton(_ type: MKDirectionsTransportType, symbol: String) -> some View {
        Button {
            model.setTransportType(type)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(
                    model.transportType == type ? MusafirTheme.cardFill : MusafirTheme.cardLabel
                )
                .frame(width: 32, height: 32)
                .background(
                    model.transportType == type ? MusafirTheme.cardLabel : Color.clear,
                    in: .circle
                )
        }
        .buttonStyle(.plain)
    }

    /// Begins following the route. Kept separate from drawing it so the user can
    /// look the route over first.
    private var startButton: some View {
        Button {
            model.startNavigation()
        } label: {
            Label("Go", systemImage: "location.north.fill")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(MusafirTheme.accent, in: .capsule)
        }
        .buttonStyle(.plain)
    }

    /// Live guidance: the next maneuver, how far to it, and what's left overall.
    /// Tapping opens the full written directions.
    private var navigationBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(MusafirTheme.cardLabel)

                VStack(alignment: .leading, spacing: 2) {
                    Text(model.currentInstruction ?? "Continue")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(MusafirTheme.cardLabel)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if let next = model.distanceToNextTurn {
                        Text(next)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(MusafirTheme.cardSecondaryLabel)
                    }
                }

                Spacer(minLength: 0)

                Button {
                    model.stopNavigation()
                } label: {
                    Text("End")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(MusafirTheme.cardLabel)
                        .padding(.horizontal, 14)
                        .frame(height: 32)
                        .background(MusafirTheme.cardStroke.opacity(0.2), in: .capsule)
                }
                .buttonStyle(.plain)
            }

            Text(model.remainingSummary ?? "")
                .font(.system(size: 13))
                .foregroundStyle(MusafirTheme.cardSecondaryLabel)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            MusafirTheme.cardFill,
            in: RoundedRectangle(cornerRadius: MusafirTheme.cardCornerRadius)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MusafirTheme.cardCornerRadius)
                .stroke(MusafirTheme.cardStroke, lineWidth: 1)
        )
    }

    /// Shown once the destination is reached, so the route ends with a word rather
    /// than the banner simply disappearing.
    private var arrivalBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(MusafirTheme.cardLabel)

            VStack(alignment: .leading, spacing: 2) {
                Text("Arrived")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(MusafirTheme.cardLabel)

                Text(model.routeDestination?.name ?? religion.placeholderName)
                    .font(.system(size: 13))
                    .foregroundStyle(MusafirTheme.cardSecondaryLabel)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Button {
                model.clearRoute()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(MusafirTheme.cardLabel)
                    .frame(width: 32, height: 32)
                    .background(MusafirTheme.cardStroke.opacity(0.2), in: .circle)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .frame(height: MusafirTheme.cardHeight)
        .background(
            MusafirTheme.cardFill,
            in: RoundedRectangle(cornerRadius: MusafirTheme.cardCornerRadius)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MusafirTheme.cardCornerRadius)
                .stroke(MusafirTheme.cardStroke, lineWidth: 1)
        )
    }

    /// Horizontally scrolling cards for the nearest prayer spaces. Tapping a card
    /// zooms the camera onto that place and opens its detail sheet.
    private var nearbyList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MusafirTheme.cardSpacing) {
                ForEach(model.cards) { card in
                    Button {
                        model.select(card.item)
                    } label: {
                        placeCard(for: card)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, MusafirTheme.cardSpacing)
        }
        .scrollClipDisabled()
    }

    private func placeCard(for card: RankedPlace) -> some View {
        HStack(spacing: 8) {
            Image(systemName: religion.markerSymbol)
                .font(.system(size: 20))
                .foregroundStyle(MusafirTheme.cardLabel)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(card.item.name ?? religion.placeholderName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(MusafirTheme.cardLabel)
                    .lineLimit(1)

                Text(card.distanceText ?? model.addressText(for: card.item))
                    .font(.system(size: 13))
                    .foregroundStyle(MusafirTheme.cardSecondaryLabel)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.leading, 14)
        .padding(.trailing, 12)
        .frame(
            width: MusafirTheme.cardWidth,
            height: MusafirTheme.cardHeight,
            alignment: .leading
        )
        .background(
            MusafirTheme.cardFill,
            in: RoundedRectangle(cornerRadius: MusafirTheme.cardCornerRadius)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MusafirTheme.cardCornerRadius)
                .stroke(
                    MusafirTheme.cardStroke,
                    lineWidth: card.item == model.selectedItem ? 2 : 1
                )
        )
    }
}

#Preview {
    NavigationTab()
}

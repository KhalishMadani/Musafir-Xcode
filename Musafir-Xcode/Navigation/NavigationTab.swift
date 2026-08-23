//
//  NavigationTab.swift
//  Musafir-Xcode
//
//  Created by Muhammad Khalish Madani on 10/05/26.
//

import SwiftUI
import MapKit

struct NavigationTab: View {
    /// One map shared by the Explore and Search tabs.
    @State private var mapModel = MapModel()
    /// Both map tabs stay alive once visited; tracking the selection tells the model
    /// which of them owns the shared camera.
    @State private var selection: MapModel.MapTab? = MapModel.MapTab.explore
    @AppStorage(Religion.storageKey) private var religion: Religion = .islam

    var body: some View {
        TabView(selection: $selection) {
            Tab("Explore", systemImage: "map", value: MapModel.MapTab.explore) {
                NavigationStack {
                    MapView(model: mapModel, tab: .explore)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .title) {
                                wordmark
                            }
                        }
                        .tint(Color.blue)
                }
            }

            Tab("Configure", systemImage: "gearshape", value: nil as MapModel.MapTab?) {
                NavigationStack {
                    ConfigureView()
                        .tint(MusafirTheme.accent)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbarBackgroundVisibility(.visible, for: .navigationBar)
                        .toolbar {
                            ToolbarItem(placement: .title) {
                                wordmark
                            }
                        }
                }
            }

            // Search sits beside the tab bar as its own circular button and expands
            // into the bottom search field, over the map the user is already on.
            Tab(value: MapModel.MapTab.search, role: .search) {
                NavigationStack {
                    SearchView(model: mapModel)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .title) {
                                wordmark
                            }
                        }
                        .tint(Color.blue)
                }
            }
        }
        .tint(MusafirTheme.accent)
        .onChange(of: selection) { _, tab in
            if let tab { mapModel.activeTab = tab }
        }
        // Presented from the TabView so a pin or card tap opens one sheet, whichever
        // of the two map tabs the user is on.
        .sheet(isPresented: $mapModel.isShowingDetail, onDismiss: mapModel.clearSelection) {
            if let item = mapModel.selectedItem {
                PlaceDetailSheet(item: item, model: mapModel, religion: religion)
            }
        }
        .sheet(isPresented: $mapModel.isShowingSteps) {
            if let route = mapModel.route {
                RouteStepsSheet(
                    route: route,
                    destinationName: mapModel.routeDestination?.name ?? religion.placeholderName
                )
            }
        }
    }

    private var wordmark: some View {
        Text("Musafir")
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(MusafirTheme.accent)
    }
}

#Preview {
    NavigationTab()
}

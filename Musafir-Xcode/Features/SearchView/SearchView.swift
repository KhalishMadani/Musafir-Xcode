//
//  SearchView.swift
//  Musafir-Xcode
//
//  Search tab. Renders the same map as Explore — sharing MapModel means the camera,
//  pins and selection carry straight over, so tapping search never swaps the map out.
//

import SwiftUI
import MapKit

struct SearchView: View {
    @Bindable var model: MapModel
    @AppStorage(Religion.storageKey) private var religion: Religion = .islam

    var body: some View {
        MapView(model: model, tab: .search)
            .searchable(
                text: $model.searchQuery,
                prompt: "Search \(religion.placeholderName)"
            )
            .onSubmit(of: .search) {
                model.searchByName()
            }
            .onChange(of: model.searchQuery) { _, newValue in
                // Results follow the typing, as in Apple Maps; clearing the field
                // drops back to the nearby prayer spaces.
                if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    model.searchNearby()
                } else {
                    model.queryChanged()
                }
            }
    }
}

#Preview {
    NavigationTab()
}

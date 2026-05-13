//
//  MapView.swift
//  Musafir-Xcode
//
//  Created by Muhammad Khalish Madani on 11/05/26.
//

import SwiftUI
import MapKit


struct MapView: View {
    let manager = CLLocationManager()
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var locationMark: [MKMapItem] = []
    
    var body: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
            ForEach(locationMark, id: \.self) { item in
                Marker(
                    item.name ?? "Coffee",
                    systemImage: "pin.circle",
                    coordinate: item.location.coordinate
                )
            }
        }
        .mapControls() {
            MapUserLocationButton()
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                Button {
                    searchMap()
                } label : {
                    Image(systemName: "bookmark.fill")
                        .resizable()
                        .frame(width: 24, height: 30)
                }
                .padding(.trailing, 30)
            }
        }

        .onAppear{
            manager.requestWhenInUseAuthorization()
        }
    }
    
    func searchMap() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "mosque"
        
        let location = manager.location
        let region = MKCoordinateRegion(
            center: location!.coordinate,
            latitudinalMeters: 2000,
            longitudinalMeters: 2000
        )
        
        request.region = region
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response else { return }
            locationMark = response.mapItems
        }
    }
}

#Preview {
    NavigationTab()
}

//
//  ExploreView.swift
//  Musafir-Xcode
//
//  Created by Muhammad Khalish Madani on 10/05/26.
//

import Foundation
import SwiftUI
import MapKit

// 1. A coordinator to receive location updates
class LocationDelegate: NSObject, CLLocationManagerDelegate {
    var onLocation: ((CLLocationCoordinate2D) -> Void)?
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coord = locations.first?.coordinate else { return }
        onLocation?(coord)
        manager.stopUpdatingLocation() // stop after first fix
    }
}


struct ExploreView: View {
    let gwk = CLLocationCoordinate2D(latitude: -8.80988271538465, longitude: 115.1675857735554)
    
    @State private var cameraLocation: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var locationManager = CLLocationManager()
    @State private var delegate = LocationDelegate()
    
    // STORE SEARCH RESULTS
    @State private var searchResults: [MKMapItem] = []
    
    var body: some View {
        Map(position: $cameraLocation) {
            UserAnnotation()
            //            Marker("GWK",systemImage: "pin", coordinate: gwk)
            // SHOW MARKERS
            ForEach(searchResults, id: \.self) { item in
                Marker(
                    item.name ?? "Coffee",
                    coordinate: item.location.coordinate
                )
            }
            
        }
        .safeAreaInset(edge: .top) {
            HStack {
                Spacer()
                Button {
                    searchPlace()
                } label : {
                    Image(systemName: "location.circle.fill")
                        .resizable()
                        .frame(width: 35, height: 35)
                }
                .padding(.trailing, 20)
            }
        }
        .onAppear() {
            delegate.onLocation = { coord in
                withAnimation {
                    cameraLocation = .region(MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    ))
                }
            }
            locationManager.delegate = delegate
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
    }
    
    func searchPlace() {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = "coffee"
        
        if let region = cameraLocation.region {
            searchRequest.region = region
        }
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let response = response else {
                print(error?.localizedDescription ?? "Unknown error")
                return
            }
            
            DispatchQueue.main.async {
                searchResults = response.mapItems
            }
        }
    }
}

#Preview {
    //    ExploreView()
    NavigationTab()
}

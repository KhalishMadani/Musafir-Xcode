//
//  ExploreView.swift
//  Musafir-Xcode
//
//  Created by Muhammad Khalish Madani on 10/05/26.
//

import Foundation
import SwiftUI
import MapKit

struct ExploreView: View {
    @State private var locationManager = LocationManager()
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    var body: some View {
        Map(position: $position) {
            UserAnnotation()
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        
    }
}

//#Preview {
////    ExploreView()
//    NavigationTab()
//}

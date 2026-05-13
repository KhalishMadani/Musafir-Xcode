//
//  LocationManager.swift
//  Musafir-Xcode
//
//  Created by Muhammad Khalish Madani on 10/05/26.
//

import Foundation
import CoreLocation
import Combine

class locate: NSObject, ObservableObject, CLLocationManagerDelegate {

    let manager = CLLocationManager()

    override init() {
        super.init()

        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
}

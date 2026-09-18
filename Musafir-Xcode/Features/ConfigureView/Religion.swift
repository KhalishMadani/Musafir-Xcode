//
//  Religion.swift
//  Musafir-Xcode
//
//  Created by Muhammad Khalish Madani on 22/08/26.
//

import Foundation

/// Religion chosen in ConfigureView. Drives which prayer spaces MapView searches for.
enum Religion: String, CaseIterable, Identifiable {
    case islam = "Islam"
    case kristen = "Kristen"
    case katolik = "Katolik"
    // Same order as the onboarding mockup.
    case budha = "Budha"
    case hindu = "Hindu"

    var id: String { rawValue }

    /// Storage key shared between ConfigureView and MapView.
    static let storageKey = "selectedReligion"

    /// Search term handed to MKLocalSearch for the nearest prayer space.
    var searchQuery: String {
        switch self {
        case .islam: "mosque"
        case .kristen: "church"
        case .katolik: "catholic church"
        case .hindu: "hindu temple"
        case .budha: "buddhist temple"
        }
    }

    /// English label shown in onboarding.
    var displayName: String {
        switch self {
        case .islam: "Muslim"
        case .kristen: "Christian"
        case .katolik: "Catholic"
        case .hindu: "Hindu"
        case .budha: "Buddhist"
        }
    }

    /// SF Symbol used for the map markers.
    var markerSymbol: String {
        switch self {
        case .islam: "moon.stars.fill"
        case .kristen, .katolik: "cross.fill"
        case .hindu, .budha: "flame.fill"
        }
    }

    /// Fallback marker title when a map item has no name.
    var placeholderName: String {
        switch self {
        case .islam: "Mosque"
        case .kristen: "Church"
        case .katolik: "Catholic Church"
        case .hindu: "Temple"
        case .budha: "Vihara"
        }
    }
}

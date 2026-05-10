//
//  NavigationTab.swift
//  Musafir-Xcode
//
//  Created by Muhammad Khalish Madani on 10/05/26.
//

import SwiftUI

struct NavigationTab: View {
    var body: some View {            TabView{
        Tab("Explore", systemImage: "map") {
            NavigationStack {
                ExploreView()
            }
        }
        Tab("Configure", systemImage: "gearshape") {
            NavigationStack {
                ConfigureView()
                    .tint(nil)
                    .navigationTitle("MUSAFIR")
            }
        }
    }
    .tint(Color.purple)
        
    }
}

#Preview {
    NavigationTab()
}

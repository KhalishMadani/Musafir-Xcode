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
                MapView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .title) {
                            Text("MUSAFIR")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color.purple)
                        }
                    }
                    .tint(Color.blue)
            }
        }
        Tab("Configure", systemImage: "gearshape") {
            NavigationStack {
                ConfigureView()
                    .tint(Color.purple)
                    .navigationBarTitleDisplayMode(.inline)
//                    .toolbarBackground(Color.purple, for: .navigationBar)
                    .toolbarBackgroundVisibility(.visible, for: .navigationBar)
                    .toolbar {
                        ToolbarItem(placement: .title) {
                            Text("MUSAFIR")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color.purple)
                        }
                    }
            }
        }
    }
    .tint(Color.purple)
        
    }
}

#Preview {
    NavigationTab()
}

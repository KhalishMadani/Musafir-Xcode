//
//  ConfigureView.swift
//  Musafir-Xcode
//
//  Created by Muhammad Khalish Madani on 10/05/26.
//

import SwiftUI

struct ConfigureView: View {
    let options = ["Islam", "Kristen", "Katolik", "Hindu", "Budha"]
    @State private var selectedOption: String = "Islam"
    
    var body: some View {
        VStack {
            Form {
                Picker("Choose Religion", selection: $selectedOption) {
                    ForEach(options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                
            }
        }
    }
}

//#Preview {
//    NavigationTab()
//}

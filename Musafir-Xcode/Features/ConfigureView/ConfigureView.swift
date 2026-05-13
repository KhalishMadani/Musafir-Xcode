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
            Picker("Choose Religion", selection: $selectedOption) {
                ForEach(options, id: \.self) { option in
                    Text(option)
                        .font(.system(size: 30,weight: .bold))
                        .tag(option)
                }
            }
            .pickerStyle(.wheel)  // or .segmented, .wheel, etc.
            .frame(height: 280)
            .padding(.top, 20)
            .padding(.bottom, 40)
            
            HStack {
                Text("Every journey is easier when you never lose connection with your faith. Whether you're in an unfamiliar city or a foreign land we guide you to the nearest prayer space")
//                    .foregroundStyle(Color.black)
                    .font(.system(size: 14,weight: .bold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
            }
            .multilineTextAlignment(.center)
            .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 30)

            
            Spacer()
        }
    }
}

//#Preview {
////    ConfigureView()
//        NavigationTab()
//}

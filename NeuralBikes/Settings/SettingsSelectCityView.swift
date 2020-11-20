//
//  SettingsSelectCityView.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 14/11/20.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import SwiftUI

struct SettingsSelectCityView: View {
    
    let defaults = UserDefaults(suiteName: Constants.appGroupsBundleID)!
    
    @Binding var selectedCity: Int
    
    var body: some View {
        VStack() {
            
            Text("SELECT_CITY_EXPLANATION")
                .frame(alignment: .leading)

            
            #if targetEnvironment(macCatalyst)
            Picker("CHANGE_CITIES", selection: $selectedCity, content: {
                ForEach(0 ..< availableCities.count) {
                    Text(Array(availableCities.keys)[$0])
                        .bold()
                        .font(.system(.body, design: .rounded))
                }
            })
            #else
            Picker(selection: $selectedCity, label: Text("Change cities")) {
                ForEach(0 ..< availableCities.count) {
                    Text(Array(availableCities.keys)[$0])
                        .bold()
                        .font(.system(.body, design: .rounded))
                }
            }
            .onChange(of: selectedCity, perform: { change in
//                changeCity(change: change)
                print("CHANGED TO \(change)")
                selectedCity = change
                $selectedCity.wrappedValue = change
            })
            
            #endif
            
            Spacer()
            
            
        }.navigationTitle(Text("SELECT_CITY"))
    }
    
    func changeCity(change: Int) {
        print("\(change) - \(Array(availableCities.keys)[change])")
        
        let apiCityName = availableCities[Array(availableCities.keys)[change]]
        
        do {
            let encodedData = try PropertyListEncoder().encode(apiCityName)
            defaults.set(encodedData, forKey: "city")
        } catch {
            fatalError("\(#function)")
        }
        
//        if let citio = apiCityName {
//            viewModel.changedCityTo(citio: citio)
//        }
    }
}

//struct SettingsSelectCityView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsSelectCityView(selectedCity: <#Binding<String>#>)
//    }
//}

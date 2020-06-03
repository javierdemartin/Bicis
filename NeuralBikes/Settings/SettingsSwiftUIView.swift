//
//  SettingsSwiftUIView.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 22/05/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import SwiftUI

struct SettingsSwiftUIView: View {
    var body: some View {
        
        VStack {
            VStack {
                // MARK: Destination Station
                HStack {
                    Image(systemName: "mappin")
                        .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                    VStack {
                        Text("Destination Station")
                            .font(.title)
                            .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                        Text("95% accuracy")
                            .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                    }
                }
                
                // MARK: Refill/Emptying
                
                HStack {
                    // - Refill
                    HStack {
                        Image(systemName: "chevron.up")
                            .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                        Text("15:00")
                            .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                    }
                    .background(Color(UIColor.systemGray2))
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    
                    // - Emptying
                    
                    HStack {
                        Image(systemName: "chevron.down")
                            .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                        Text("18:00")
                            .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                    }
                    .background(Color(UIColor.systemGray2))
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    
                }
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                
                Text("Free docks at destination")
                
                HStack {
                    // - Now
                    VStack {
                        Text("Now")
                        Text("21")
                            .fontWeight(.heavy)
                    }
                    .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                    
                    Image(systemName: "arrow.right")
                        .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                    
                    // - Time of arrival
                    VStack {
                        Text("11:50")
                        Text("20")
                            .fontWeight(.heavy)
                    }
                    .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .cornerRadius(10)
            
            VStack {
                Text("Closest alternative station")
                HStack {
                    Image(systemName: "hand.point.right.fill")
                    .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                    VStack {
                        Text("Closest Station")
                            .fontWeight(.bold)
                        Text("15 free docks")
                    }
                }
            }
        }
    }
}

struct SettingsSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsSwiftUIView()
    }
}

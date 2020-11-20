//
//  SettingsSwiftUIView.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 22/05/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import SwiftUI

struct DashboardViewController: View {
    
    @ObservedObject var viewModel: DashboardViewModel
    
    @State var destinationStationName: String = "DESTINATION_STATION"
    @State var nextRefillTime: String?
    @State var nextDischargeTime: String?
    
    @Environment(\.presentationMode) var presentationMode
    
    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
        
        destinationStationName = viewModel.destinationStationString
        nextRefillTime = viewModel.nextRefillTime
        nextDischargeTime = viewModel.nextDischargeTime
    }
    
    @ViewBuilder
    var body: some View {
        
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading) {
                
                Spacer().frame(height: 20)
                
                VStack(alignment: .leading) {
                    // MARK: Destination Station
                    HStack {
                        VStack(alignment: .leading) {
                            Text(viewModel.destinationStationString)
                                .font(.system(.title, design: .rounded))
                                .fontWeight(.heavy)
                                .lineLimit(2)
                                .padding(EdgeInsets(
                                    top: Constants.cornerRadius,
                                    leading: Constants.cornerRadius,
                                    bottom: Constants.cornerRadius,
                                    trailing: Constants.cornerRadius))
                            
                            PredictionGraphViewRepresentable(prediction: viewModel.predictionArray, availability: viewModel.availabilityArray)
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 60, maxHeight: 80)
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 17, trailing: 0))
                            
                            if viewModel.predictionPrecission != nil {
                                
                                Divider()
                                
                                Text(viewModel.predictionPrecission!)
                                    .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                                .stroke(Color(UIColor(named: "TextAndGraphColor")!), lineWidth: Constants.cornerRadius / 6)
                        )
                    }
                    .background(Color(UIColor.systemBackground))
                    .padding(EdgeInsets(
                        top: 0,
                        leading: 3 * Constants.cornerRadius,
                        bottom: 3 * Constants.cornerRadius,
                        trailing: Constants.cornerRadius * 3))
                    
                    Divider()
                        .padding(EdgeInsets(
                            top: 0,
                            leading: 3 * Constants.cornerRadius,
                            bottom: 0,
                            trailing: 3 * Constants.cornerRadius))
                    
                    VStack(alignment: .leading) {
                                                
                        HStack {
                            
                            Spacer()
                            
                            
                            PillBoxView(image: "chevron.up", title: "REFILL", value: viewModel.nextRefillTime ?? "?")
                                     
                            Spacer(minLength: 30)
                            
                            PillBoxView(image: "chevron.down", title: "DISCHARGE", value: viewModel.nextDischargeTime ?? "?")
                            
                            Spacer()
                        }
                    }
                    .padding(EdgeInsets(
                        top: Constants.cornerRadius,
                        leading: 2 * Constants.cornerRadius,
                        bottom: Constants.cornerRadius,
                        trailing: 2 * Constants.cornerRadius))
                }
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .center, spacing: 16, pinnedViews: [], content: {
                    
                    PillBoxView(title: "FREE_BIKES", value: "\(viewModel.stations.map({ $0.freeBikes }).reduce(0, +))")
                    PillBoxView(title: "FREE_RACKS", value: "\(viewModel.stations.map({ $0.freeRacks }).reduce(0, +))")
                    
                    PillBoxView(title: "AVAILABLE_RACKS", value: "\(viewModel.stations.map({ $0.freeRacks + $0.freeBikes }).reduce(0, +))")
                    
                    Menu {
                        Text("LOAD_FACTOR_EXPLANATION")
                            .lineLimit(nil)
                    } label : {
                        PillBoxView(title: "LOAD_FACTOR", value: "\(viewModel.loadFactor)%")
                    }.menuStyle(BorderlessButtonMenuStyle())
                    
                    Menu {
                        ForEach(viewModel.fullStations, id: \.self) { i in
                            Text(i)
                        }
                        
                    } label: {
                        PillBoxView(title: "FULL_STATIONS", value: "\(viewModel.stations.map({ $0.freeRacks }).filter({$0 == 0}).count)")                    }
                    
                    Menu {
                        ForEach(viewModel.freeStations, id: \.self) { i in
                            Text(i)
                        }
                        
                    } label: {
                        PillBoxView(title: "EMPTY_STATIONS", value: "\(viewModel.stations.map({ $0.freeBikes }).filter({$0 == 0}).count)")
                    }
                    
                    
                    
                    
                }).padding()
                
                VStack(alignment: .leading) {
                    Text("FREE_DOCKS_DESTINATION_PLACEHOLDER")
                    
                    HStack {
                        Spacer()
                        // - Now
                        
                        PillBoxView(title: "NOW", value: viewModel.actualDocksAtDestination)
                        
                        Image(systemName: "arrow.right")
                            .padding(EdgeInsets(
                                top: 10,
                                leading: 2 * Constants.cornerRadius,
                                bottom: 10,
                                trailing: 2 * Constants.cornerRadius))
                        
                        // - Time of arrival
                        PillBoxView(title: "\(viewModel.expectedArrivalTime)", value: viewModel.expectedDocksAtArrivalTime)
                        
                        
                        Spacer()
                    }
                }
                .padding(EdgeInsets(
                    top: Constants.cornerRadius,
                    leading: 3 * Constants.cornerRadius,
                    bottom: Constants.cornerRadius,
                    trailing: 3 * Constants.cornerRadius))
                
//                Button("CLOSE", action: {
//                    self.presentationMode.wrappedValue.dismiss()
//                })
                
                
                Text(viewModel.numberOfTimesLaunched)
                    .padding(EdgeInsets(
                        top: 0,
                        leading: 3 * Constants.cornerRadius,
                        bottom: 0,
                        trailing: 3 * Constants.cornerRadius))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
            .edgesIgnoringSafeArea(.bottom)
        }.accentColor(Color.primary)
        
    }
}

struct PillBoxView: View {
    
    @State var image: String?
    @State var title: LocalizedStringKey
    @State var value: String
    
    var body: some View {
        VStack(alignment: .center) {
            
            if let image = image {
                Label(title, systemImage: image)
            } else {
                
                Text(title)
                    .font(.system(.body, design: .rounded))
                    .lineLimit(1)
            }
            
            
            Divider()
                .foregroundColor(.primary)
            Text(value)
                .fontWeight(.heavy)
                .font(.system(.body, design: .rounded))
        }
        .padding(EdgeInsets(
            top: Constants.cornerRadius,
            leading: 2 * Constants.cornerRadius,
            bottom: Constants.cornerRadius,
            trailing: 2 * Constants.cornerRadius))
            .background(Color(UIColor.systemBackground))
            .cornerRadius(Constants.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .stroke(Color(UIColor(named: "TextAndGraphColor")!), lineWidth: Constants.cornerRadius / 6)
        )
    }
}

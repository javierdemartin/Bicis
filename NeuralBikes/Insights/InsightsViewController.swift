//
//  SettingsSwiftUIView.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 22/05/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import SwiftUI

struct InsightsViewController: View {
    
    @ObservedObject var viewModel: InsightsViewModel
    
    @State var destinationStationName: String = "DESTINATION_STATION"
    @State var nextRefillTime: String?
    @State var nextDischargeTime: String?
    
    init(viewModel: InsightsViewModel) {
        self.viewModel = viewModel
        
        destinationStationName = viewModel.destinationStationString
        nextRefillTime = viewModel.nextRefillTime
        nextDischargeTime = viewModel.nextDischargeTime
    }
    
    @ViewBuilder
    var body: some View {
        
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading) {
                
                HStack(spacing: Constants.cornerRadius) {
                    Spacer()
                    RoundedRectangle(cornerRadius: Constants.cornerRadius)
                        .fill(Color(.systemFill))
                        .frame(
                            width: 60,
                            height: 6
                    )
                    
                    Spacer()
                }
                .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                
                VStack(alignment: .leading) {
                    // MARK: Destination Station
                    HStack {
                        VStack(alignment: .leading) {
                            Text(viewModel.destinationStationString)
                                .font(.system(.title, design: .rounded))
                                .fontWeight(.heavy)
                                .padding(EdgeInsets(
                                    top: Constants.cornerRadius,
                                    leading: Constants.cornerRadius,
                                    bottom: Constants.cornerRadius,
                                    trailing: Constants.cornerRadius))
                            
                            PredictionGraphViewRepresentable(prediction: viewModel.predictionArray, availability: viewModel.availabilityArray)
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 100, maxHeight: 100)
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
                        
//                        Text("OPERATIONS_DESCRIPTION")
                        
                        HStack {
                            
                            Spacer()
                            
                            // - Refill
                            VStack {
                                HStack {
                                    Image(systemName: "chevron.up")
                                        .padding(EdgeInsets(top: Constants.cornerRadius, leading: 10, bottom: 0, trailing: 0))
                                    Text("REFILL")
                                        .padding(EdgeInsets(top: Constants.cornerRadius, leading: 0, bottom: 0, trailing: 10))
                                }
                                
                                Divider()
                                
                                Text(viewModel.nextRefillTime ?? "?")
                                    .fontWeight(.heavy)
                                    .font(.system(.body, design: .rounded))
                                    .padding(EdgeInsets(
                                        top: Constants.cornerRadius,
                                        leading: Constants.cornerRadius,
                                        bottom: Constants.cornerRadius,
                                        trailing: Constants.cornerRadius))
                            }
                            .background(Color(UIColor.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.cornerRadius)
                                    .stroke(Color(UIColor(named: "TextAndGraphColor")!), lineWidth: Constants.cornerRadius / 6)
                            )
                                          
                            Spacer(minLength: 30)
                            
                            VStack {
                                HStack {
                                    Image(systemName: "chevron.down")
                                        .padding(EdgeInsets(top: Constants.cornerRadius, leading: 10, bottom: 0, trailing: 0))
                                    Text("DISCHARGE")
                                        .padding(EdgeInsets(top: Constants.cornerRadius, leading: 0, bottom: 0, trailing: 10))
                                }
                                
                                Divider()
                                Text(viewModel.nextDischargeTime ?? "?")
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.heavy)
                                    .padding(EdgeInsets(
                                        top: Constants.cornerRadius,
                                        leading: Constants.cornerRadius,
                                        bottom: Constants.cornerRadius,
                                        trailing: Constants.cornerRadius))
                                
                            }
                            .background(Color(UIColor.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.cornerRadius)
                                    .stroke(Color(UIColor(named: "TextAndGraphColor")!), lineWidth: Constants.cornerRadius / 6)
                            )
                            
                            Spacer()
                        }
                    }
                    .padding(EdgeInsets(
                        top: Constants.cornerRadius,
                        leading: 3 * Constants.cornerRadius,
                        bottom: Constants.cornerRadius,
                        trailing: 3 * Constants.cornerRadius))
                    
                    VStack(alignment: .leading) {
                        Text("FREE_DOCKS_DESTINATION_PLACEHOLDER")
                        
                        HStack {
                            Spacer()
                            // - Now
                            VStack(alignment: .center) {
                                Text("NOW")
                                    .font(.system(.body, design: .rounded))
                                Divider()
                                Text(viewModel.actualDocksAtDestination)
                                    .fontWeight(.heavy)
                                    .font(.system(.body, design: .rounded))
                            }
                            .padding(EdgeInsets(
                                top: 10,
                                leading: 2 * Constants.cornerRadius,
                                bottom: 10,
                                trailing: 2 * Constants.cornerRadius))
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(Constants.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.cornerRadius)
                                    .stroke(Color(UIColor(named: "TextAndGraphColor")!), lineWidth: Constants.cornerRadius / 6)
                            )
                            
                            Image(systemName: "arrow.right")
                                .padding(EdgeInsets(
                                    top: 10,
                                    leading: 2 * Constants.cornerRadius,
                                    bottom: 10,
                                    trailing: 2 * Constants.cornerRadius))
                            
                            // - Time of arrival
                            VStack(alignment: .center) {
                                Text(viewModel.expectedArrivalTime)
                                    .font(.system(.body, design: .rounded))
                                Divider()
                                Text(viewModel.expectedDocksAtArrivalTime)
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
                            
                            Spacer()
                        }
                    }
                    .padding(EdgeInsets(
                        top: Constants.cornerRadius,
                        leading: 3 * Constants.cornerRadius,
                        bottom: Constants.cornerRadius,
                        trailing: 3 * Constants.cornerRadius))
                }
                
                Text(viewModel.numberOfTimesLaunched)
                    .padding(EdgeInsets(
                        top: 0,
                        leading: 3 * Constants.cornerRadius,
                        bottom: 0,
                        trailing: 3 * Constants.cornerRadius))
                
                Spacer()
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}

//struct SettingsSwiftUIView_Previews: PreviewProvider {
//
//    static var previews: some View {
//
//        InsightsSwiftUIView(viewModel: InsightsViewModel(compositeDisposable: CompositeDisposable(), dataManager: DataManager(localDataManager: DefaultLocalDataManager(), remoteDataManager: DefaultRemoteDataManager(), bikeServicesDataManager: NextBikeBikeServicesDataManager()), destinationStation: NextBikeStation(id: "dfasdf", freeBikes: 5, freeDocks: 5, stationName: "AMEZTOLA", latitude: 5.0, longitude: 5.0)))
//    }
//}

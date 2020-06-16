//
//  SettingsSwiftUIView.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 22/05/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import SwiftUI
//import Foundation
import ReactiveSwift


import SwiftUI

fileprivate enum ConstantsMajid {
    static let radius: CGFloat = 16
    static let indicatorHeight: CGFloat = 6
    static let indicatorWidth: CGFloat = 60
    static let snapRatio: CGFloat = 0.25
    static let minHeightRatio: CGFloat = 0.3
}

struct BottomSheetView<Content: View>: View {
    
    @State var isOpen: Bool = false

    let maxHeight: CGFloat
    let minHeight: CGFloat
    let content: Content

    @GestureState private var translation: CGFloat = 0

    private var offset: CGFloat {
        isOpen ? 0 : maxHeight - minHeight
    }

    private var indicator: some View {
        RoundedRectangle(cornerRadius: ConstantsMajid.radius)
            .fill(Color.secondary)
            .frame(
                width: ConstantsMajid.indicatorWidth,
                height: ConstantsMajid.indicatorHeight
        ).onTapGesture {
            self.isOpen.toggle()
        }
    }

    init(isOpen: Bool, maxHeight: CGFloat, @ViewBuilder content: () -> Content) {
        self.minHeight = maxHeight * ConstantsMajid.minHeightRatio
        self.maxHeight = maxHeight
        self.content = content()
        self.isOpen = isOpen
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                self.indicator.padding()
                self.content
            }
            .frame(width: geometry.size.width, height: self.maxHeight, alignment: .top)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(ConstantsMajid.radius)
            .frame(height: geometry.size.height, alignment: .bottom)
            .offset(y: max(self.offset + self.translation, 0))
            .animation(.interactiveSpring())
            .gesture(
                DragGesture().updating(self.$translation) { value, state, _ in
                    state = value.translation.height
                }.onEnded { value in
                    let snapDistance = self.maxHeight * ConstantsMajid.snapRatio
                    guard abs(value.translation.height) > snapDistance else {
                        return
                    }
                    self.isOpen = value.translation.height < 0
                }
            )
        }
    }
}

// MARK: HEHE

struct InsightsSwiftUIView: View {
    
    @ObservedObject var viewModel: InsightsViewModel
    
    @State var destinationStationName: String = "DESTINATION_STATION"
    @State var accuracyString: LocalizedStringKey = "CALCULATING_PRECISSION"
    @State var freeDocksAtDestination: LocalizedStringKey = "FREE_DOCKS_DESTINATION_PLACEHOLDER"
    @State var explanationStringKey: LocalizedStringKey = "EXPLANATION_INSIGHTS"
    
    @State var dischargeStringKey: LocalizedStringKey = "DISCHARGE";
    @State var refillStringKey: LocalizedStringKey = "REFILL";
    
    
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
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 100)
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
                        
                        Divider()
                        Text(viewModel.predictionPrecission)
                            .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))

                    }
                }
                .background(Color(UIColor.systemBackground))
                .cornerRadius(Constants.cornerRadius)
                .padding(EdgeInsets(
                    top: 0,
                    leading: 3 * Constants.cornerRadius,
                    bottom: 3 * Constants.cornerRadius,
                    trailing: Constants.cornerRadius * 3))
                
                Divider()
                
                // MARK: Refill/Emptying
                  
                .padding(EdgeInsets(
                    top: 0,
                    leading: 3 * Constants.cornerRadius,
                    bottom: 0,
                    trailing: 3 * Constants.cornerRadius))
                
                VStack {
                    
                    Text("Predicción de operaciones de recarga y vaciamiento en la estación.")
                    
                    HStack {
                        
                        Spacer()
                        
                        // - Refill
                        VStack {
                            HStack {
                                Image(systemName: "chevron.up")
                                .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 0))
                                Text(refillStringKey)
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
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
                        .cornerRadius(Constants.cornerRadius)
                        
                        Spacer(minLength: 30)
                        
                        VStack {
                            HStack {
                            Image(systemName: "chevron.down")
                                .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 0))
                                Text(dischargeStringKey)
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
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
                        .cornerRadius(Constants.cornerRadius)
                        
                        Spacer()
                    }
                }
                .padding(EdgeInsets(
                top: Constants.cornerRadius,
                leading: 3 * Constants.cornerRadius,
                bottom: Constants.cornerRadius,
                trailing: 3 * Constants.cornerRadius))
                
                VStack {
                    Text(freeDocksAtDestination)
                    
                    HStack {
                        Spacer()
                        // - Now
                        VStack(alignment: .center) {
                            Text("Now")
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
        .background(Color(UIColor.systemFill))
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        .edgesIgnoringSafeArea(.bottom)
    }
    
}

//struct SettingsSwiftUIView_Previews: PreviewProvider {
//
//    static var previews: some View {
//
//        InsightsSwiftUIView(viewModel: InsightsViewModel(compositeDisposable: CompositeDisposable(), dataManager: DataManager(localDataManager: DefaultLocalDataManager(), remoteDataManager: DefaultRemoteDataManager(), bikeServicesDataManager: NextBikeBikeServicesDataManager()), destinationStation: NextBikeStation(id: "dfasdf", freeBikes: 5, freeDocks: 5, stationName: "AMEZTOLA", latitude: 5.0, longitude: 5.0)))
//    }
//}

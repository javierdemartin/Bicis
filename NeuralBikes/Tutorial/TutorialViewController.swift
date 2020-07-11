//
//  TutorialViewController.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 05/07/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import SwiftUI
import Combine

struct TutorialViewController: View {
    
    @ObservedObject var viewModel: TutorialViewModel
    
    init(viewModel: TutorialViewModel) {
        
        self.viewModel = viewModel
    }
    
    @ViewBuilder
    var body: some View {
        
        VStack(alignment: .center) {
            
            // Hackitty hack to fill the screen
            HStack {
                Spacer()
            }
            
            VStack(alignment: .leading) {
                
                Text("Neural Bikes")
                    .font(.system(.largeTitle, design: .rounded))
                    .foregroundColor(Color.white)
                    .fontWeight(.heavy)
                    .padding()
                
                Text("Bike sharing, but better")
                    .padding()
                    .foregroundColor(Color.white)
                
                Text("It's time you enjoy bike sharing again. Gather insights of how the bike sharing system is behaving. Check daily availability predictions made with machine learning and compare it against with real values.")
                    .padding()
                    .foregroundColor(Color.white)
                
                VStack(alignment: .leading) {
                    
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.white)
                        Text("Location not shared")
                            .foregroundColor(Color.white)
                            .font(.system(.body, design: .rounded))
                    }
                    .padding()
                    
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.white)
                        Text("No trackers installed or information sent to third parties")
                            .foregroundColor(Color.white)
                            .font(.system(.body, design: .rounded))
                    }
                    .padding()
                    
                    HStack {
                        Image(systemName: "waveform.path.ecg")
                            .foregroundColor(.white)
                        Text("Check predictions and history on the graph")
                            .foregroundColor(Color.white)
                            .font(.system(.body, design: .rounded))
                    }
                    .padding()
                    
                    PredictionGraphViewRepresentable(prediction: [1,2,2,2,2,2,2,3,3,3,3,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,3,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3], availability: [0,0,0,0,0,0,0,1,1,1,1,1,2,2,2,2,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,3,3,3,3,3,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3])
                        .frame(minWidth: 0, maxWidth: 300, minHeight: 100, maxHeight: 100)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
                    
                    Spacer()
                    VStack(alignment: .center) {
                        HStack {
                        
                            Button(action: {
                                UIApplication.shared.open(URL(string: "https://twitter.com/javierdemartin")!)
                            }) {
                                Text("@javierdemartin")
                                    .foregroundColor(.white)
                                    .fontWeight(.heavy)
                                    .font(.system(.body, design: .rounded))
                                    .padding()
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Constants.cornerRadius)
                                            .stroke(Color.white, lineWidth: 2)
                                        
                                    )
                            }
                            
                            Button(action: {
                                UIApplication.shared.open(URL(string: "https://twitter.com/neuralbikes")!)
                            }) {
                                Text("@neuralbikes")
                                    .foregroundColor(.white)
                                    .fontWeight(.heavy)
                                    .font(.system(.body, design: .rounded))
                                    .padding()
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Constants.cornerRadius)
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .center) {
                            Button(action: {
                                viewModel.didTapFinishTutorial()
                            }) {
                                Text("Take me to the app")
                                    .foregroundColor(.white)
                                    .fontWeight(.heavy)
                                    .font(.system(.title3, design: .rounded))
                                    .padding()
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Constants.cornerRadius)
                                            .stroke(Color.white, lineWidth: 2)           
                                    )
                            }
                        }
                    }
                }
                .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/, 10)
            }
            
        }
        .background(Color(.systemBlue).edgesIgnoringSafeArea(.all))
        .frame(minWidth: 0, maxWidth: 500, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
    }
}

//struct TutorialViewController_Previews: PreviewProvider {
//    static var previews: some View {
//        TutorialViewController()
//    }
//}

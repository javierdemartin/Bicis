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
            
            Spacer(minLength: 50)
            
            Text("Neural Bikes")
                .font(.system(.largeTitle, design: .default))
                .fontWeight(.heavy)
            
            VStack(alignment: .leading) {
                
                HStack {
                    Image(systemName: "0.circle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 30, weight: .regular))
                        .padding()
                    VStack(alignment: .leading) {
                        Text("ML_PREDICTIONS_TITLE")
                            .font(.system(.body, design: .rounded))
                            .bold()
                            .fixedSize(horizontal: false, vertical: true)
                        Text("ML_PREDICTIONS_BODY")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding()
                
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 30, weight: .regular))
                        .padding()
                    
                    VStack(alignment: .leading) {
                        Text("INFORMATION_TITLE")
                            .font(.system(.body, design: .rounded))
                            .bold()
                            .fixedSize(horizontal: false, vertical: true)
                        Text("INFORMATION_BODY")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                }
                .padding()
                
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 30, weight: .regular))
                        .padding()
                    
                    VStack(alignment: .leading) {
                        Text("PRIVACY_TITLE")
                            .font(.system(.body, design: .rounded))
                            .bold()
                            .fixedSize(horizontal: false, vertical: true)
                        Text("PRIVACY_BODY")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding()
                
            }
            
            
            Spacer()
            
            
            
            Button(action: {
                viewModel.didTapFinishTutorial()
            }) {
                Text("FINISH_ONBOARDING")
                    .fontWeight(.heavy)
                    .padding()
            }
            .foregroundColor(.white)
            .background(Color.accentColor)
            .cornerRadius(8)
            
            Button(action: {
                NBActions.sendToPrivacyPolicy()
            }) {
                Text("PRIVACY_POLICY")
                    .fontWeight(.heavy)
                    .padding()
            }
        }
        .frame(minWidth: 0, maxWidth: 500, alignment: .topLeading)
        
    }
}

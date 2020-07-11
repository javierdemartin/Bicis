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
    
    let mlTitle: LocalizedStringKey = "ML_PREDICTIONS_TITLE"
    let mlBody: LocalizedStringKey = "ML_PREDICTIONS_BODY"
    
    let informationTitle: LocalizedStringKey = "INFORMATION_TITLE"
    let informationBody: LocalizedStringKey = "INFORMATION_BODY"
    
    let privacyTitle: LocalizedStringKey = "PRIVACY_TITLE"
    let privacyBody: LocalizedStringKey = "PRIVACY_BODY"
    
    let finishOnboardButton: LocalizedStringKey = "FINISH_ONBOARDING"


    
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
                                Text(mlTitle)
                                    .font(.system(.body, design: .rounded))
                                    .bold()
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(mlBody)
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
                                Text(informationTitle)
                                    .font(.system(.body, design: .rounded))
                                    .bold()
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(informationBody)
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
                                Text(privacyTitle)
                                    .font(.system(.body, design: .rounded))
                                    .bold()
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(privacyBody)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding()
                        
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.didTapFinishTutorial()
                    }) {
                        Text(finishOnboardButton)
                            .fontWeight(.heavy)
                            .padding()
                    }.buttonStyle(DefaultButtonStyle())
                
                
            }
//            .edgesIgnoringSafeArea(.all)
            .frame(minWidth: 0, maxWidth: 500, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)

    }
}

//struct TutorialViewController_Previews: PreviewProvider {
//    static var previews: some View {
//        TutorialViewController()
//    }
//}

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
        
        GeometryReader { fullView in
            Spacer()
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(self.viewModel.tutorial, id: \.self) { index in
                            GeometryReader { geo in
                                TutorialCard(title: index.title, description: index.body)
                                    .frame(width: fullView.size.width * 0.7, height: fullView.size.height, alignment: .top)
                                    .rotation3DEffect(.degrees(-Double(geo.frame(in: .global).midX - fullView.size.width / 2) / 10), axis: (x: 0, y: 1, z: 0))
                            }
                            .frame(width: 250)
                        }
                    }
                    .padding(.horizontal, (fullView.size.width - 250) / 2)
                }
                
                Button(action: {
                    print("Button action")
                    viewModel.didTapFinishTutorial()
                }) {
                    Text("Take me to the app")
                        .foregroundColor(.white)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue, lineWidth: 2)
                        ) 
                }
                .background(Color.blue)
            }
            
            
        }
    }
}

//struct TutorialViewController_Previews: PreviewProvider {
//    static var previews: some View {
//        TutorialViewController(viewModel: TutorialViewModel())
//    }
//}

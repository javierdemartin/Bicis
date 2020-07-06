//
//  TutorialCardView.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 05/07/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import SwiftUI
import Combine

struct TutorialCard: View {
    
    @State var title: String
    @State var description: String
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text(title)
                .font(.system(.title, design: .rounded))
                .fontWeight(.heavy)
                .padding()
            
            Text(description)
                .padding()
                    
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black, lineWidth: 2)
        )
    }
}

struct TutorialCardView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialCard(title: "Tutorial Page", description: "This is the body of the current page")
    }
}

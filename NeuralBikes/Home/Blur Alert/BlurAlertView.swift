//
//  BlurAlertView.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 11/07/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import SwiftUI

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}

struct BlurAlertView: View {
    
    @State var title: LocalizedStringKey = "BLUR_ALERT_TITLE"
    @State var subtitle: LocalizedStringKey = "BLUR_ALERT_SUBTITLE"
    
    @State var areDocksBeingShown = true
    
    var body: some View {
        
        VStack(alignment: .center) {
            
            Image(systemName: "circle")
                .foregroundColor(.gray)
                .font(.system(size: 80, weight: .regular))
                .padding()
            Text(title)
                .foregroundColor(.gray)
                .font(.system(.title, design: .rounded)).bold()
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .foregroundColor(.gray)
                .font(.system(.body, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)

        }
        .frame(minWidth: 200, maxWidth: 300, minHeight: 200, maxHeight: 300, alignment: .center)
        .padding()
        .cornerRadius(25)
        
    }
}

struct BlurAlertView_Previews: PreviewProvider {
    static var previews: some View {
        BlurAlertView()
    }
}

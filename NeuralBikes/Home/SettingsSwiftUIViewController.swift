//
//  SettingsSwiftUIViewController.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 03/07/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import SwiftUI

struct SettingsSwiftUIViewController: View {
    
//    @ObservedObject var viewModel: SettingsViewModel
    
//    init(viewModel: SettingsViewModel) {
//
//        self.viewModel = viewModel
//    }
    
    @State var appVersion: String = "App Version"
    
    init() {
        guard let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else { return }

        guard let bundleString = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else { return }
        
        appVersion = versionString + "(\(bundleString)"
        
        dump(appVersion)
    }
    
    var body: some View {
        
        VStack {
            Image(systemName: "AppIcon60x60")
            Text(appVersion)
                .font(.system(.title, design: .rounded))
            
//            Button(action: {
//                
//            }, label: {
//                
//            })
            
            Text("Receive description of the app bla bla bla")
            
            Button(action: {
                
            }, label: {
                /*@START_MENU_TOKEN@*/Text("Button")/*@END_MENU_TOKEN@*/
            })
        }
        
    }
}


struct SettingsSwiftUIViewController_Previews: PreviewProvider {
    
    static var previews: some View {
        SettingsSwiftUIViewController()
    }
}

//
//  SettingsViewControllerSwiftUI.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 11/10/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import SwiftUI
import UIKit

struct SettingsViewControllerSwiftUI: View {
    
    var colors = ["Red", "Green", "Blue", "Tartan"]
    
    let defaults = UserDefaults(suiteName: Constants.appGroupsBundleID)!
    
    weak var coordinatorDelegate: SettingsViewModelCoordinatorDelegate?
    
    let viewModel: SettingsViewModel

    
    init(viewModel: SettingsViewModel) {

        self.viewModel = viewModel
    }
    
    
    @State private var selectedColor = 0
    
    var body: some View {
        VStack {
                        
            VStack {
                Image(uiImage: UIImage(named: "AppIcon60x60")!)
                    .frame(width: 60, height: 60, alignment: .center)
                    .padding()
                    .cornerRadius(9.0)
                
                Text(NBDefaults.longAppVersion!)
                    .bold()
                    .font(.system(.body, design: .rounded))
                    .padding()
            }.padding()
            
            Button(action: {
                NBActions.sendToMail()
            }, label: {
                Text("FEEDBACK_BUTTON")
                    .bold()
                    .font(.system(.body, design: .rounded))
            })
            .padding()
            
            
            Text("HOW_TO_USE")
                .bold()
                .font(.system(.body, design: .rounded))
                .padding()
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            Picker(selection: $selectedColor, label: Text("Please choose a color")) {
                ForEach(0 ..< availableCities.count) {
                    Text(Array(availableCities.keys)[$0])
                        .bold()
                        .font(.system(.body, design: .rounded))
                }
            }
            .onChange(of: selectedColor, perform: { change in
                print("\(change) - \(Array(availableCities.keys)[change])")
                
                let apiCityName = availableCities[Array(availableCities.keys)[change]]
                
                do {
                    let encodedData = try PropertyListEncoder().encode(apiCityName)
                    defaults.set(encodedData, forKey: "city")
                } catch {
                    fatalError("\(#function)")
                }
                
                if let citio = apiCityName {
                    viewModel.changedCityTo(citio: citio)
                }
                
            })
            .padding()
            
            Button(action: {
                NBActions.sendToMail()
            }, label: {
                Text("RESTORE_PURCHASES_BUTTON")
                    .bold()
                    .font(.system(.body, design: .rounded))
            }).padding()
            
            Button(action: {
                NBActions.sendToMail()
            }, label: {
                Text("REPLAY_TUTORIAL_BUTTON")
                    .bold()
                    .font(.system(.body, design: .rounded))
            }).padding()
        }
    }
}

class SettingsHostingController: UIHostingController<SettingsViewControllerSwiftUI> {
    
    var coordinatorDelegate: SettingsViewModelCoordinatorDelegate?
    
    init(viewModel: SettingsViewModel) {
        super.init(rootView: SettingsViewControllerSwiftUI(viewModel: viewModel))
    }
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

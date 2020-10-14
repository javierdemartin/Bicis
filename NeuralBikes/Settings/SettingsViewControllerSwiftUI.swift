//
//  SettingsViewControllerSwiftUI.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 11/10/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import SwiftUI
import UIKit
import StoreKit
import Combine

struct SettingsViewControllerSwiftUI: View {
    
    let defaults = UserDefaults(suiteName: Constants.appGroupsBundleID)!
    
    weak var coordinatorDelegate: SettingsViewModelCoordinatorDelegate?
    
    var viewModel: SettingsViewModel
    
    var cancellableBag = Set<AnyCancellable>()
    
    @State var productos: [MyPurchase] = []
    
    @ObservedObject var otherViewModel = OtherSettingsViewModel()
        
    init(viewModel: SettingsViewModel) {
        
        self.viewModel = viewModel
    }
    
    
    @State private var selectedColor = 0
    
    var body: some View {
        
        ScrollView {
            VStack(alignment: .leading) {
                
                VStack(alignment: .center) {
                    Image(uiImage: UIImage(named: "AppIcon60x60")!)
                        .frame(width: 60, height: 60, alignment: .center)
                        .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 4))
                                .shadow(radius: 2)
                    
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
                                
                if self.otherViewModel.products.count > 0 {
                    
                    ForEach(self.otherViewModel.products) { a in
                        
                        Button(action: {
                            StoreKitProducts.store.buyProduct(a.skProd)
                        }, label: {
                            Text("\(a.localizedTitle) \(a.skProd.localizedPrice)")
                                .bold()
                                .font(.system(.body, design: .rounded))
                                .padding()
                        })
                        .foregroundColor(.white)
                        .background(Color.accentColor)
                        .cornerRadius(8)
                    }
                    
                    Button(action: {
                        NBActions.sendToMail()
                    }, label: {
                        Text("RESTORE_PURCHASES_BUTTON")
                            .bold()
                            .font(.system(.body, design: .rounded))
                            .padding()
                    })
                    
                    Text("DONATIONS_EXPLANATION")
                        .font(.caption)
                }
                
                
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
                    Text("REPLAY_TUTORIAL_BUTTON")
                        .bold()
                        .font(.system(.body, design: .rounded))
                }).padding()
            }
        }.padding()
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


extension SKProduct {
    fileprivate static var formatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }
    
    var localizedPrice: String {
        if self.price == 0.00 {
            return "Get"
        } else {
            let formatter = SKProduct.formatter
            formatter.locale = self.priceLocale
            
            guard let formattedPrice = formatter.string(from: self.price) else {
                return "Unknown Price"
            }
            
            return formattedPrice
        }
    }
}

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
    
    
    @State private var selectedCity = 0
    
    var body: some View {
        
        ScrollView(showsIndicators: false) {
            VStack(alignment: .center) {
                
                VStack(alignment: .center) {
                    VStack {
                        
                    }
                    Image(uiImage: UIImage(named: "AppIcon60x60")!)
                        .frame(width: 60, height: 60, alignment: .center)
                        .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 4))
                    
                    Text(NBDefaults.longAppVersion!)
                        .bold()
                        .font(.system(.body, design: .rounded))
                }
                .padding()
                
                HStack {
                    Button(action: {
                        NBActions.sendToTwitter(profile: "javierdemartin")
                    }, label: {
                            Text("@javierdemartin")
                            .bold()
                            .font(.system(.body, design: .rounded))
                                .padding()
                    })
                    
                    Button(action: {
                        NBActions.sendToTwitter(profile: "neuralbikes")
                    }, label: {
                            Text("@neuralbikes")
                            .bold()
                            .font(.system(.body, design: .rounded))
                                .padding()
                    })
                }
                
                Divider()
                
                Button(action: {
                    NBActions.sendToMail()
                }, label: {
                    Text("FEEDBACK_BUTTON")
                        .bold()
                        .font(.system(.body, design: .rounded))
                        .padding()
                })
                
                Divider()
                
                Text("HOW_TO_USE")
                    .bold()
                    .font(.system(.body, design: .rounded))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                
                Picker(selection: $selectedCity, label: Text("Change cities")) {
                    ForEach(0 ..< availableCities.count) {
                        Text(Array(availableCities.keys)[$0])
                            .bold()
                            .font(.system(.body, design: .rounded))
                    }
                }
                .onChange(of: selectedCity, perform: { change in
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
                                
                if self.otherViewModel.products.count > 0 {
                    
                    Divider()
                    
                    VStack(alignment: .center) {
                        
                        HStack {
                            Text("DONATIONS_EXPLANATION")
                                .bold()
                                .font(.system(.body, design: .rounded))
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                        }
                        
                        ForEach(self.otherViewModel.products) { a in
                            
                            Button(action: {
                                StoreKitProducts.store.buyProduct(a.skProd)
                            }, label: {
                                HStack {
                                    Spacer()
                                    Text("\(a.localizedTitle) \(a.skProd.localizedPrice)")
                                        .bold()
                                        .font(.system(.body, design: .rounded))
                                        .padding()
                                    Spacer()
                                    
                                }
                            })
                            .foregroundColor(.white)
                            .background(Color.accentColor)
                            .cornerRadius(8)
                        }
                        
                        Button(action: {
                            DispatchQueue.main.async {
                                StoreKitProducts.store.restorePurchases()
                            }
                        }, label: {
                            Text("RESTORE_PURCHASES_BUTTON")
                                .bold()
                                .font(.system(.body, design: .rounded))
                                .padding()
                        })
                        
                    }.padding()
                }
                
                
                Divider()
                
                Button(action: {
                    NBActions.sendToWeb()
                }, label: {
                    Text("SEND_TO_WEBSITE")
                        .bold()
                        .font(.system(.body, design: .rounded))
                })
                
            }
        }.padding()
        .onAppear(perform: {
            
            guard let data = defaults.value(forKey: "city") as? Data else {
               return
            }

            guard let decoded = try? PropertyListDecoder().decode(City.self, from: data) else {
               return
            }
            
            let selected = Array(availableCities.keys).index(of: decoded.formalName)
            
            print(selected)
            
            selectedCity = selected!
        })
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

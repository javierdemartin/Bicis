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

struct SettingsViewController: View {
    
    let defaults = UserDefaults(suiteName: Constants.appGroupsBundleID)!
    
    weak var coordinatorDelegate: SettingsViewModelCoordinatorDelegate?
    
    var viewModel: SettingsViewModel
    
    var cancellableBag = Set<AnyCancellable>()
    
    @State var productos: [MyPurchase] = []
    
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var otherViewModel = OtherSettingsViewModel()
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }
    
    @State var selectedCity = 0
    
    var body: some View {
        
            NavigationView {
                 
                List {

                    NavigationLink(destination: SettingsSelectCityView(selectedCity: $selectedCity)) {
                        
                        HStack {
                            Text("Select City")
                            Spacer()
                            Text(Array(availableCities.keys)[selectedCity])
                        }
                    }
                    
                    Section(header: Text("SOCIAL"), content: {
                        Button(action: {
                            NBActions.sendToTwitter(profile: "javierdemartin")
                        }, label: {
                            Text("@javierdemartin")
                        })
                        
                        Button(action: {
                            NBActions.sendToTwitter(profile: "neuralbikes")
                        }, label: {
                            Text("@neuralbikes")
                        })
                    })
                    
                    Section(header: Text("DONATIONS_SUPPORT"), footer: Text("DONATIONS_EXPLANATION"), content: {
                        ForEach(self.otherViewModel.products) { a in

                            Button(action: {
                                StoreKitProducts.store.buyProduct(a.skProd)
                            }, label: {
                                Text("\(a.localizedTitle) \(a.skProd.localizedPrice)")
                            })
                        }
                        
                        Button(action: {
                            DispatchQueue.main.async {
                                StoreKitProducts.store.restorePurchases()
                            }
                        }, label: {
                            Text("RESTORE_PURCHASES_BUTTON")
                        })
                    })
                    
                    Section {
                        
                        Button(action: {
                            NBActions.sendToWeb()
                        }, label: {
                            Text("SEND_TO_WEBSITE")
                        })
                        
                        Button(action: {
                            NBActions.sendToPrivacyPolicy()
                        }, label: {
                            Text("PRIVACY_POLICY")
                        })
                        
                        Button(action: {
                            NBActions.sendToMail()
                        }, label: {
                            Text("FEEDBACK_BUTTON")
                        })
                    }
                    
                    Section {
                        Text(NBDefaults.longAppVersion!)
                        
                        Button(action: {
                            SKStoreReviewController.requestReview()
                        }) {
                         Text("Review")
                        }
                    }
                    
                }.listStyle(InsetGroupedListStyle())
                .navigationTitle(Text("SETTINGS"))
            }
            .onChange(of: selectedCity, perform: { value in
                changeCity(change: value)
            }).onAppear(perform: {
                
                guard let data = defaults.value(forKey: "city") as? Data else {
                    return
                }
    
                guard let decoded = try? PropertyListDecoder().decode(City.self, from: data) else {
                    return
                }
    
                if let currentCityIndex = Array(availableCities.keys).index(of: decoded.formalName) {
                    selectedCity = currentCityIndex
                }
            })
    }
    
    func changeCity(change: Int) {
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
    }
}

class SettingsHostingController: UIHostingController<SettingsViewController> {
    
    var coordinatorDelegate: SettingsViewModelCoordinatorDelegate?
    
    init(viewModel: SettingsViewModel) {
        super.init(rootView: SettingsViewController(viewModel: viewModel))
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

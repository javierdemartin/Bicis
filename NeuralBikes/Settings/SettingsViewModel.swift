//
//  CityViewModel.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 02/12/2019.
//  Copyright © 2019 Javier de Martín Gil. All rights reserved.
//

import Foundation
import CoreLocation
import StoreKit
import Combine

protocol SettingsViewModelCoordinatorDelegate: class {
    func changedCitySelectionInPickerView(city: City)
}

enum DonationDescriptions: String {
    case firstTier = "com.javierdemartin.bici.donation_level_1"
    case secondTier = "com.javierdemartin.bici.donation_level_2"
    case thirdTier = "com.javierdemartin.bici.donation_level_3"
}

struct MyPurchase: Identifiable {
    var id = UUID()
    var localizedTitle: String
    var identifier: String
    var skProd: SKProduct
}

class OtherSettingsViewModel: ObservableObject {
    
    @Published var products: [MyPurchase] = []
    
    init() {
        StoreKitProducts.store.requestProducts({ success, products in

            if success {

                guard let productos = products else { return }

                DispatchQueue.main.async {
                    productos.forEach({ prod in  self.products.append(MyPurchase(localizedTitle: prod.localizedTitle, identifier: prod.productIdentifier, skProd: prod))
                    })
                }
            }
        })
    }
}

class SettingsViewModel {

    weak var coordinatorDelegate: SettingsViewModelCoordinatorDelegate?
    
    func changedCityTo(citio: City) {
        coordinatorDelegate?.changedCitySelectionInPickerView(city: citio)
    }

    init() {
    }
}

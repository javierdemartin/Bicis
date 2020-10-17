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

protocol SettingsViewModelDataManager {
    func saveCurrentCity(apiCityName: City, completion: @escaping (Result<Void>) -> Void)
    func getCurrentCityFromDefaults(completion: @escaping (Result<City>) -> Void)
}

protocol SettingsViewModelDelegate: class {
    func selectCityInPickerView(city: String)
    func errorSubmittingCode(with errorString: String)
    func updateCitiesPicker(sortedCities: [String])
    func presentAlertViewWithError(title: String, body: String)
    func shouldShowLogOutButton()
}

protocol SettingsViewModelCoordinatorDelegate: class {
    func presenTutorialViewController()
    func changedCitySelectionInPickerView(city: City)
    func dismissSettingsViewController()
}

enum DonationDescriptions: String {
    case firstTier = "com.javierdemartin.bici.donation_level_1"
    case secondTier = "com.javierdemartin.bici.level_two_donation"
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

    var availableCitiesModel = Binding<[String]>(value: Array(availableCities.keys))
    
    weak var delegate: SettingsViewModelDelegate?
    weak var coordinatorDelegate: SettingsViewModelCoordinatorDelegate?
    var city: City?
    
    let dataManager: SettingsViewModelDataManager

    func sendFeedBackEmail() {
        NBActions.sendToMail()
    }
    
    func presentTutorialViewControllerFromCoordinatorDelegate() {
        coordinatorDelegate?.presenTutorialViewController()
    }

    func prepareViewForAppearance() {
        
        if let currentCity = self.city {
            if currentCity.allowsLogIn {
                delegate?.shouldShowLogOutButton()
            }
        }

        dataManager.getCurrentCityFromDefaults(completion: { cityResult in
            switch cityResult {

            case .success(let cityFromDefaults):
                self.delegate?.selectCityInPickerView(city: cityFromDefaults.formalName)

            case .error(let errorCity):

                self.dataManager.saveCurrentCity(apiCityName: availableCities.first!.value, completion: { _ in })
                self.delegate?.selectCityInPickerView(city: availableCities.first!.value.formalName)
                print(errorCity)
            }
        })
    }

    func dismissingSettingsViewController() {

        guard let city = self.city else { return }

        // Get the correct `City` data structure
        guard let selectedCity = availableCities[city.formalName] else { return }

        self.city = selectedCity

        dataManager.saveCurrentCity(apiCityName: selectedCity, completion: { _ in })

        coordinatorDelegate?.changedCitySelectionInPickerView(city: selectedCity)
    }
    
    func changedCityTo(citio: City) {
        coordinatorDelegate?.changedCitySelectionInPickerView(city: citio)
    }
    

    func setUpBindings() {

    }
    
    let locationService: LocationServiceable

    init(currentCity: City?, locationService: LocationServiceable, dataManager: SettingsViewModelDataManager) {

        self.dataManager = dataManager
        self.locationService  = locationService

        setUpBindings()

        self.city = currentCity
        
//        StoreKitProducts.store.requestProducts({ success, products in
//
//            if success {
//
//                guard let productos = products else { return }
//
//                DispatchQueue.main.async {
//                    self.products = productos
//                }
//
//            }
//        })
    }
}

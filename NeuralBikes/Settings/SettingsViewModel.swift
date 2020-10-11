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
    func logOut()

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
    func presentRestorePurchasesViewControllerFromCoordinatorDelegate()
    func dismissSettingsViewController()
}

enum DonationDescriptions: String {

    case firstTier = "com.javierdemartin.bici.level_one_donation"
    case secondTier = "com.javierdemartin.bici.level_two_donation"
}

class SettingsViewModel: ObservableObject {

    var availableCitiesModel = Binding<[String]>(value: Array(availableCities.keys))

    weak var delegate: SettingsViewModelDelegate?
    weak var coordinatorDelegate: SettingsViewModelCoordinatorDelegate?
    var city: City?
//    let usernameTextfieldContinuousTextValues = MutableProperty<String?>(nil)
//    let passwordTextfieldContinuousTextValues = MutableProperty<String?>(nil)
//    let logInButtonIsEnabled = MutableProperty(false)
    
    let dataManager: SettingsViewModelDataManager

    func sendFeedBackEmail() {
        NBActions.sendToMail()
    }

    /// Presents RestorePurchasesViewController and dismisses SettingsViewController that is currently presented as a modal
    func presentRestorePurchasesViewControllerFromCoordinatorDelegate() {
        coordinatorDelegate?.presentRestorePurchasesViewControllerFromCoordinatorDelegate()
    }
    
    func presentTutorialViewControllerFromCoordinatorDelegate() {
        coordinatorDelegate?.presenTutorialViewController()
    }
    
    func logOut() {
        dataManager.logOut()
        coordinatorDelegate?.dismissSettingsViewController()
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

    func setUpBindings() {

//        let usernameIsNotEmpty = usernameTextfieldContinuousTextValues.producer.map({ $0?.isEmpty ?? true }).negate()
//        let passwordIsNotEmpty = usernameTextfieldContinuousTextValues.producer.map({ $0?.isEmpty ?? true }).negate()
//        compositeDisposable += logInButtonIsEnabled <~ usernameIsNotEmpty.and(passwordIsNotEmpty)
    }
    
    let locationService: LocationServiceable

    init(currentCity: City?, locationService: LocationServiceable, dataManager: SettingsViewModelDataManager) {

        self.dataManager = dataManager
        self.locationService  = locationService

        setUpBindings()

        self.city = currentCity
    }
}

//extension SettingsViewModel: LocationServicesDelegate {
//    func tracingLocation(_ currentLocation: CLLocation) {
//        print(currentLocation)
//    }
//
//    func tracingLocationDidFailWithError(_ error: NSError) {
//        fatalError()
//    }
//}

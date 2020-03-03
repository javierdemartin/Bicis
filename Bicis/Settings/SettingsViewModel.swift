//
//  CityViewModel.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 02/12/2019.
//  Copyright © 2019 Javier de Martín Gil. All rights reserved.
//

import Foundation
import ReactiveSwift
import CoreLocation

protocol SettingsViewModelDataManager {
    func saveCurrentCity(apiCityName: City, completion: @escaping (Result<Void>) -> Void)
    func getCurrentCityFromDefaults(completion: @escaping (Result<City>) -> Void)

}

protocol SettingsViewModelDelegate: class {
    func selectCityInPickerView(city: String)
    func errorSubmittingCode(with errorString: String)
    func updateCitiesPicker(sortedCities: [String])
}

protocol SettingsViewModelCoordinatorDelegate: class {

    func changedCitySelectionInPickerView(city: City)
}

class SettingsViewModel {

    var availableCitiesModel = Binding<[String]>(value: Array(availableCities.keys))

    weak var delegate: SettingsViewModelDelegate?
    weak var coordinatorDelegate: SettingsViewModelCoordinatorDelegate?

    var city: City?

    let usernameTextfieldContinuousTextValues = MutableProperty<String?>(nil)
    let passwordTextfieldContinuousTextValues = MutableProperty<String?>(nil)
    let logInButtonIsEnabled = MutableProperty(false)

    let compositeDisposable: CompositeDisposable

    let dataManager: SettingsViewModelDataManager

    func saveCity(cityName: City) {

        dataManager.saveCurrentCity(apiCityName: cityName, completion: { saveCurrentCityResult in
            switch saveCurrentCityResult {

            case .success:
                break
            case .error:
                // TODO: Show error, prevent using the home view
                break
            }
        })
    }

    func sendFeedBackEmail() {
        guard let url = URL(string: "mailto:javierdemartin@gmail.com") else { return }
        UIApplication.shared.openURL(url)
    }

    func changedCityInPickerView(city: String) {

        // Get the correct `City` data structure
        guard let selectedCity = availableCities[city] else { return }

        dataManager.saveCurrentCity(apiCityName: selectedCity, completion: { _ in })

        coordinatorDelegate?.changedCitySelectionInPickerView(city: selectedCity)
    }

    func prepareViewForAppearance() {

        dataManager.getCurrentCityFromDefaults(completion: { cityResult in
            switch cityResult {

            case .success(let cityFromDefaults):
                self.delegate?.selectCityInPickerView(city: cityFromDefaults.formalName)

            case .error(let errorCity):

                self.dataManager.saveCurrentCity(apiCityName: availableCities.first!.value, completion: { _ in })
                self.delegate?.selectCityInPickerView(city: availableCities.first!.value.formalName)
                print(errorCity)
                break
            }
        })
    }

    func dismissingSettingsViewController() {

        dataManager.getCurrentCityFromDefaults(completion: { cityResult in
            switch cityResult {

            case .success(let cityFromDefaults):
                self.changedCityInPickerView(city: cityFromDefaults.formalName)
                self.city = cityFromDefaults
            case .error(_):
                break
            }
        })

    }

    func setUpBindings() {

        let usernameIsNotEmpty = usernameTextfieldContinuousTextValues.producer.map({ $0?.isEmpty ?? true }).negate()
        let passwordIsNotEmpty = usernameTextfieldContinuousTextValues.producer.map({ $0?.isEmpty ?? true }).negate()

        compositeDisposable += logInButtonIsEnabled <~ usernameIsNotEmpty.and(passwordIsNotEmpty)
    }

    init(currentCity: City?, compositeDisposable: CompositeDisposable, dataManager: SettingsViewModelDataManager) {

        self.compositeDisposable = compositeDisposable
        self.dataManager = dataManager

        setUpBindings()

        self.city = currentCity
    }
}

extension SettingsViewModel: LocationServicesDelegate {
    func tracingLocation(_ currentLocation: CLLocation) {
        print(currentLocation)
    }

    func tracingLocationDidFailWithError(_ error: NSError) {
        fatalError()
    }
}

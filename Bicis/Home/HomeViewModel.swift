//
//  HomeViewModel.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 02/11/2019.
//  Copyright © 2019 Javier de Martín Gil. All rights reserved.
//

import Foundation
import ReactiveSwift
import CoreLocation
import MapKit

protocol HomeViewModelCoordinatorDelegate: class {
    func showSettingsViewController()
    func modallyPresentRoutePlannerWithRouteSelected(stationsDict: BikeStation, closestAnnotations: [BikeStation])
    func presentRestorePurchasesViewControllerFromCoordinatorDelegate()

}

protocol HomeViewModelDataManager {
    func getCurrentCity(completion: @escaping (Result<City>) -> Void)
    func checkUserCredentials(completion: @escaping (Result<UserCredentials>) -> Void)
    func getStations(city: String, completion: @escaping (Result<[BikeStation]>) -> Void)
    func hasUnlockedFeatures(completion: @escaping (Result<Bool>) -> Void)
    func getAllDataFromApi(city: String, station: String, completion: @escaping(Result<MyAllAPIResponse>) -> Void)
}

protocol HomeViewModelDelegate: class {
    func receivedError(with errorString: String)
    func segueToSettingsViewController()
    func drawPrediction(data: [Int], prediction: Bool)
    func changedUserLocation(location: CLLocation)
    func centerMap(on point: CLLocationCoordinate2D, coordinateSpan: MKCoordinateSpan)
    func dismissGraphView()
    func removePinsFromMap()
    func presentAlertViewWithError(title: String, body: String)
}

extension HomeViewModel: LocationServicesDelegate {
    func tracingLocation(_ currentLocation: CLLocation) {
        print(currentLocation)
    }

    func tracingLocationDidFailWithError(_ error: NSError) {

    }
}

class HomeViewModel {

    var city: City?
    let compositeDisposable: CompositeDisposable

    var destinationStation = Binding<BikeStation?>(value: nil)

    weak var delegate: HomeViewModelDelegate?
    weak var coordinatorDelegate: HomeViewModelCoordinatorDelegate?

    let dataManager: HomeViewModelDataManager

    let stations = Binding<[BikeStation]>(value: [])

    let stationsDict = Binding<[String: BikeStation]>(value: [:])

    init(city: City?, compositeDisposable: CompositeDisposable, dataManager: HomeViewModelDataManager) {

        self.city = city
        self.compositeDisposable = compositeDisposable
        self.dataManager = dataManager

        LocationServices.sharedInstance.delegate = self
        LocationServices.sharedInstance.locationManager?.requestWhenInUseAuthorization()
        LocationServices.sharedInstance.locationManager?.startUpdatingLocation()

        if let currentCity = self.city {
            getMapPinsFrom(city: currentCity)
        }
    }

    func hasUnlockedFeatures(completion: @escaping(Bool) -> Void) {

        if UITestingHelper.sharedInstance.isUITesting() {
            completion(true)
        }

        dataManager.hasUnlockedFeatures(completion: { result in

            switch result {

            case .success(let hasUnlocked):
                completion(hasUnlocked)
            case .error:
                completion(false)
            }

        })
    }

    func selectedRoute(station: BikeStation) {

        dataManager.hasUnlockedFeatures(completion: { [weak self] hasUnlockedResult in

            guard let self = self else { fatalError() }

            switch hasUnlockedResult {

            case .success(let hasUnlocked):
                if hasUnlocked {

                    let closestAnnotations = self.sortStationsNearTo(location: station.location)

                    self.coordinatorDelegate?.modallyPresentRoutePlannerWithRouteSelected(stationsDict: station, closestAnnotations: closestAnnotations)
                } else if !hasUnlocked {
                    self.coordinatorDelegate?.presentRestorePurchasesViewControllerFromCoordinatorDelegate()
                }
            case .error:
                self.coordinatorDelegate?.presentRestorePurchasesViewControllerFromCoordinatorDelegate()
            }
        })
    }

    func getCurrentCity(completion: @escaping(Result<City>) -> Void) {

        dataManager.getCurrentCity(completion: { cityResult in
            switch cityResult {

            case .success(let city):
                completion(.success(city))

            case .error(let err):
                print("ERROR \(err)")
            }
        })
    }

    /// Called from the `SettingsViewModel` when a new city is selected
    func removeAnnotationsFromMap() {
        delegate?.removePinsFromMap()
    }

    func getMapPinsFrom(city: City) {

        dataManager.getStations(city: city.formalName, completion: { resultStations in

            switch resultStations {

            case .success(let res):

                // Sort by closeness

                res.forEach({ individualStation in
                    self.stationsDict.value[individualStation.stationName] = individualStation
                })

                self.stations.value = res
            case .error:
                break
            }
        })
    }

    func sortStationsNearTo(location: CLLocation) -> [BikeStation] {

        /// Mutating operation
        stations.value.sort(by: { $0.distance(to: location) < $1.distance(to: $0.location) })

        return Array(stations.value.dropFirst().prefix(3))
    }

    func getAllDataFromApi(city: String, station: String, completion: @escaping(Result<[String:[Int]]>) -> Void) {

        dataManager.getAllDataFromApi(city: city, station: station, completion: { result in

            switch result {

            case .success(let datos):

                let sortedNowKeysAndValues = Array(datos.values.today).sorted(by: { $0.0 < $1.0 })
                let sortedPredictionKeysAndValues = Array(datos.values.prediction).sorted(by: { $0.0 < $1.0 })

                var sortedNow: [Int] = []
                var sortedPrediction: [Int] = []

                sortedNowKeysAndValues.forEach({ sortedNow.append($0.value )})
                sortedPredictionKeysAndValues.forEach({ sortedPrediction.append($0.value )})

                // Get the remainder values for the prediction

                let payload = ["prediction": sortedPrediction, "today": sortedNow]

                self.delegate?.drawPrediction(data: sortedPrediction, prediction: true)
                self.delegate?.drawPrediction(data: sortedNow, prediction: false)

                completion(.success(payload))

            case .error(let apiError):
                //self.delegate?.presentAlertViewWithError(title: "Error", body: apiError.localizedDescription)
                break
            }
        })
    }
}

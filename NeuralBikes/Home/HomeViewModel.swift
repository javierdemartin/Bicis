//
//  HomeViewModel.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 02/11/2019.
//  Copyright © 2019 Javier de Martín Gil. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import Combine

protocol HomeViewModelCoordinatorDelegate: class {
    func showSettingsViewController()
    func modallyPresentRoutePlannerWithRouteSelected(stationsDict: BikeStation, closestAnnotations: [BikeStation])
    func presentRestorePurchasesViewControllerFromCoordinatorDelegate()
    func presentLogInViewController()
    func presentScannerViewController()
}

protocol HomeViewModelDataManager {
    func getCurrentCity(completion: @escaping (Result<City>) -> Void)
    func checkUserCredentials(completion: @escaping (Result<UserCredentials>) -> Void)
    func getStations(city: String, completion: @escaping (Result<[BikeStation]>) -> Void)
    func hasUnlockedFeatures(completion: @escaping (Result<Bool>) -> Void)
    func getAllDataFromApi(city: String, station: String, completion: @escaping(Result<MyAllAPIResponse>) -> Void)
    func getPredictionForStation(city: String, type: String, name: String, completion: @escaping (Result<MyAPIResponse>) -> Void)
    func addStationStatistics(for id: String, city: String)
    func isUserLoggedIn(completion: @escaping (Result<LogInResponse>) -> Void)
    func rent(bike number: Int, completion: @escaping(Result<Void>) -> Void)
    func getActiveRentals(completion: @escaping(Result<GetActiveRentalsResponse>) -> Void)
}

protocol HomeViewModelDelegate: class {
    func receivedError(with errorString: String)
    func drawPrediction(data: [Int], prediction: Bool)
    func centerMap(on point: CLLocationCoordinate2D, coordinateSpan: MKCoordinateSpan)
    func selectClosestAnnotationGraph(stations: [BikeStation], currentLocation: CLLocation)
    func dismissGraphView()
    func removePinsFromMap()
    func presentAlertViewWithError(title: String, body: String)
    func shouldShowRentBikeButton()
    func shouldHideRentBikeButton()
    func showActiveRentedBike(number: String)
}

class HomeViewModel: ObservableObject {

    var currentCity: City?

    var currentSelectedStationIndex: Int = 0
    
    let locationService: LocationServiceable

    var latestSelectedAnnotation: MKAnnotation?
    var latestSelectedBikeStation: BikeStation?

    var destinationStation = Binding<BikeStation?>(value: nil)

    weak var delegate: HomeViewModelDelegate?
    weak var coordinatorDelegate: HomeViewModelCoordinatorDelegate?

    let dataManager: HomeViewModelDataManager

//    let stations = Binding<[BikeStation]>(value: [])
    @Published var stations: [BikeStation] = []
    @Published var stationsDictCombine: [String: BikeStation] = [:]

    let stationsDict = Binding<[String: BikeStation]>(value: [:])

    init(city: City?, dataManager: HomeViewModelDataManager, locationService: LocationServiceable) {

        self.currentCity = city
        self.dataManager = dataManager
        
        self.locationService = locationService
        
        setUpLocation()
        
        setUpBindings()

        if let currentCity = self.currentCity {
            getMapPinsFrom(city: currentCity)
            
            if currentCity.allowsLogIn {
                self.delegate?.shouldShowRentBikeButton()
            }
        }
    }
    
    var cancellableBag = Set<AnyCancellable>()
    
    func setUpBindings() {
        
        locationService.locationPublisher.sink(receiveValue: { location in
            
            self.delegate?.centerMap(on: location.coordinate, coordinateSpan: Constants.narrowCoordinateSpan)
        }).store(in: &cancellableBag)
    }
    
    func viewWillAppear() {
        
        if let currentCity = self.currentCity {
            if currentCity.allowsLogIn {
                delegate?.shouldShowRentBikeButton()
                getActiveRentals()
            }
        }
    }
    
    func getActiveRentals() {
        
        dataManager.getActiveRentals(completion: { rentalsResult in
            switch rentalsResult {
                
            case .success(let activeRentals):
                print(activeRentals)
                
                if activeRentals.rentalCollection.count > 0 {
                    self.delegate?.showActiveRentedBike(number: activeRentals.rentalCollection[0].bike)
                }
                
            case .error(let error):
                self.delegate?.receivedError(with: error.localizedDescription)
            }
        })
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

                    let closestAnnotations = Array(self.sortStationsNearTo(self.stations, location: station.location).dropFirst().prefix(3))

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

                self.stations = res

                if let locationFromDevice = self.locationService.currentLocation {
                    self.stations = self.sortStationsNearTo(res, location: locationFromDevice)
                    self.delegate?.selectClosestAnnotationGraph(stations: self.stations, currentLocation: locationFromDevice)
                }

            case .error:
                break
            }
        })
    }
    
    func setUpLocation() {
        
        if UITestingHelper.sharedInstance.isUITesting() { return }
        
        switch locationService.getPermissionStatus() {
        case .granted:
            locationService.startMonitoring()
        case .denied:
            break
        case .notDetermined:
            locationService.requestPermissions()
        }
    }

    func sortStationsNearTo(_ values: [BikeStation], location: CLLocation) -> [BikeStation] {

        self.stations.sort(by: { $0.distance(to: location) < $1.distance(to: $0.location) })

        return Array(stations)
    }

    func getAllDataFromApi(city: String, station: String, completion: @escaping(Result<[String: [Int]]>) -> Void) {
        
        dataManager.hasUnlockedFeatures(completion: { hasPaid in
          
            switch hasPaid {
            case .success(let paid):
                if paid {
                    
                    self.dataManager.getAllDataFromApi(city: city, station: station, completion: { result in

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
                            
                            self.latestSelectedBikeStation?.availabilityArray = sortedNow
                            self.latestSelectedBikeStation?.predictionArray = sortedPrediction

                            self.delegate?.drawPrediction(data: sortedPrediction, prediction: true)
                            self.delegate?.drawPrediction(data: sortedNow, prediction: false)

                            completion(.success(payload))

                        case .error:
                            break
                        }
                    })
                } else {
                    self.dataManager.getPredictionForStation(city: city, type: "prediction", name: station, completion: { result in
                        switch result {
                            
                        case .success(let datos):
                            
                            let sortedPredictionKeysAndValues = Array(datos.values).sorted(by: { $0.0 < $1.0 })

                            var sortedPrediction: [Int] = []

                            sortedPredictionKeysAndValues.forEach({ sortedPrediction.append($0.value )})

                            // Get the remainder values for the prediction

                            let payload = ["prediction": sortedPrediction]

                            self.delegate?.drawPrediction(data: sortedPrediction, prediction: true)

                            completion(.success(payload))

                        case .error:
                            break
                        }
                    })
                }
            case .error:
                break
            }
            
        })
    }
    
    // MARK: RENT PROCESS
    func startRentProcess() {
        
        hasUnlockedFeatures(completion: { hasPaid in
            
            if hasPaid {
                self.dataManager.isUserLoggedIn(completion: { result in
                            switch result {
                            case .success(let logInResponse):
                                print(logInResponse)
                                DispatchQueue.main.async {
                                    self.coordinatorDelegate?.presentScannerViewController()
                                }
                            case .error:
                                self.coordinatorDelegate?.presentLogInViewController()
                            }
                        })
            } else {
                self.coordinatorDelegate?.presentRestorePurchasesViewControllerFromCoordinatorDelegate()
            }
        })
    }
    
    func finishRentProcess(bike number: Int?) {
        
        guard let number = number else {
            self.delegate?.receivedError(with: "NO BIKE")
            return
        }
        
        dataManager.isUserLoggedIn(completion: { result in
            switch result {
            case .success(let logInResponse):
                print(logInResponse)
                self.dataManager.rent(bike: number, completion: { rentResult in
                    switch rentResult {
                        
                    case .success:
                        self.getActiveRentals()
                    case .error(let error):
                        self.delegate?.receivedError(with: error.localizedDescription.replacingOccurrences(of: "%bike", with: "\(number)"))
                    }
                })
            case .error(let error):
                self.delegate?.receivedError(with: error.localizedDescription)
            }
        })
    }
}

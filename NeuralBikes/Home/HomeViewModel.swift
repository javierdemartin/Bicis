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
}

protocol HomeViewModelDataManager {
    func getCurrentCity(completion: @escaping (Result<City>) -> Void)
    
    func getStations(city: String, completion: @escaping (Result<[BikeStation]>) -> Void)
    func getAllDataFromApi(city: String, station: String, completion: @escaping(Result<NeuralBikeAllAPIResponse>) -> Void)
    func getPredictionForStation(city: String, type: String, name: String, completion: @escaping (Result<MyAPIResponse>) -> Void)
    func addStationStatistics(for id: String, city: String)
}

protocol HomeViewModelDelegate: class {
    func receivedError(with errorString: String)
    func drawPrediction(data: [Int], prediction: Bool)
    func centerMap(on point: CLLocationCoordinate2D, coordinateSpan: MKCoordinateSpan)
    func selectClosestAnnotationGraph(stations: [BikeStation], currentLocation: CLLocation)
    func dismissGraphView()
    func removePinsFromMap()
    func presentAlertViewWithError(title: String, body: String)
    
}

class HomeViewModel: ObservableObject {

    var currentCity: City?

    var currentSelectedStationIndex: Int = 0
    
    let locationService: LocationServiceable

    var latestSelectedAnnotation: MKAnnotation?
    var latestSelectedBikeStation: BikeStation?

    weak var delegate: HomeViewModelDelegate?
    weak var coordinatorDelegate: HomeViewModelCoordinatorDelegate?

    let dataManager: HomeViewModelDataManager

    @Published var stations: [BikeStation] = []
    @Published var stationsDictCombine: [String: BikeStation] = [:]

    @Published var stationsDict: [String: BikeStation] = [:]

    init(city: City?, dataManager: HomeViewModelDataManager, locationService: LocationServiceable) {

        self.currentCity = city
        self.dataManager = dataManager
        
        self.locationService = locationService
        
        setUpBindings()

        if let currentCity = self.currentCity {
            getMapPinsFrom(city: currentCity)
        }
    }
    
    var cancellableBag = Set<AnyCancellable>()
    
    func setUpBindings() {
        
        locationService.locationPublisher.sink(receiveValue: { location in
            self.delegate?.centerMap(on: location.coordinate, coordinateSpan: Constants.narrowCoordinateSpan)
        }).store(in: &cancellableBag)
    }
    
    func selectedRoute(station: BikeStation) {

        let closestAnnotations = Array(self.sortStationsNearTo(self.stations, location: station.location).dropFirst().prefix(3))

        self.coordinatorDelegate?.modallyPresentRoutePlannerWithRouteSelected(stationsDict: station, closestAnnotations: closestAnnotations)
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
                    self.stationsDict[individualStation.stationName] = individualStation
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
            // If the user denies it
            if currentCity == nil {
                coordinatorDelegate?.showSettingsViewController()
            }
            
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
    }
}

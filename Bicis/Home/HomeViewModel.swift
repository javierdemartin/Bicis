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

protocol HomeViewModelCoordinatorDelegate: class {
    func didTapRestart()
    func showSettingsViewController()
}

protocol HomeViewModelDataManager {

    func getCurrentCity(completion: @escaping (Result<City>) -> Void)
    func checkUserCredentials(completion: @escaping (Result<UserCredentials>) -> Void)
    func getStations(city: String, completion: @escaping (Result<[BikeStation]>) -> Void)
    func getPredictionForStation(city: String, type: String, name: String, completion: @escaping(MyAPIResponse?) -> Void)
}

protocol HomeViewModelDelegate: class {
    func receivedError(with errorString: String)
    func segueToSettingsViewController()
    func drawPrediction(data: [Int], prediction: Bool)
    func changedUserLocation(location: CLLocation)
    func centerMap(on point: CLLocationCoordinate2D)
    func dismissGraphView()
    func removePinsFromMap()
}

class Binding<T> {

    var value: T {
        didSet {
            listener?(value)
        }
    }
    private var listener: ((T) -> Void)?
    init(value: T) {
        self.value = value
    }
    func bind(_ closure: @escaping (T) -> Void) {
        closure(value)
        listener = closure
    }
}

extension HomeViewModel: LocationServicesDelegate {
    func tracingLocation(_ currentLocation: CLLocation) {
        print(currentLocation)
    }

    func tracingLocationDidFailWithError(_ error: NSError) {
        // TODO: Error
        print(error)
    }
}

class HomeViewModel {

    var city: City?
    let compositeDisposable: CompositeDisposable

    weak var delegate: HomeViewModelDelegate?
    weak var coordinatorDelegate: HomeViewModelCoordinatorDelegate?

    let dataManager: HomeViewModelDataManager

    let stations = Binding<[BikeStation]>(value: [])

    let stationsDict = Binding<[String: BikeStation]>(value: [:])

    func calculateRmseFrom(prediction: [Int], actual: [Int]) {

        guard let maxPrediction = prediction.max() else { return }
        guard let maxAvailability = actual.max() else { return }

        var maxValue = max(maxPrediction, maxAvailability)

        var rmseResult = 0.0

        for element in 0..<actual.count {
            rmseResult += pow(Double(prediction[element] - actual[element]), 2.0)
        }

        rmseResult = sqrt(1/Double(actual.count) * rmseResult)

        print("RMSE \(rmseResult)%")
    }

    func getCurrentCity(completion: @escaping(Result<City>) -> Void) {

        dataManager.getCurrentCity(completion: { cityResult in
            switch cityResult {

            case .success(let city):
//                let centerCoordinates = CLLocationCoordinate2D(latitude: CLLocationDegrees(city.latitude), longitude: CLLocationDegrees(city.longitude))
//
//                self.delegate?.centerMap(on: centerCoordinates)

                completion(.success(city))

            case .error(let err):
                print("ERROR \(err)")
            }
        })
    }

    func removeAnnotationsFromMap() {

        delegate?.removePinsFromMap()
    }

    func getMapPinsFrom(city: City) {

        dataManager.getStations(city: city.formalName, completion: { resultStations in

            switch resultStations {

            case .success(let res):

                res.forEach({ individualStation in
                    self.stationsDict.value[individualStation.stationName] = individualStation
                })

                self.stations.value = res
            case .error:
                break
            }
        })
    }

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

    func getApiData(city: String, type: String, station: String, prediction: Bool, completion: @escaping(Result<[Int]>) -> Void) {

        dataManager.getPredictionForStation(city: city, type: type, name: station, completion: { [weak self] res in

            guard let self = self else { fatalError() }

            if let datos = res {

                let sortedKeysAndValues = Array(datos.values).sorted(by: { $0.0 < $1.0 })

                var datosa: [Int] = []

                sortedKeysAndValues.forEach({ datosa.append($0.value )})

                self.delegate?.drawPrediction(data: datosa, prediction: prediction)

                completion(.success(datosa))

            }
        })
    }
}

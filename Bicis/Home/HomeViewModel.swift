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

//    stations.bind { stations in
//
//        let currentLocation = location
//
//        let nearestPin: BikeStation? = stations.reduce((CLLocationDistanceMax, nil)) { (nearest, pin) in
//            let coord = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude), longitude:  CLLocationDegrees(pin.longitude))
//            let loc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
//            let distance = currentLocation.distance(from: loc)
//            return distance < nearest.0 ? (distance, pin) : nearest
//        }.1
//
//        print(nearestPin)
//
//    }
}

class HomeViewModel {

    var city: City?
    let compositeDisposable: CompositeDisposable

    weak var delegate: HomeViewModelDelegate?
    weak var coordinatorDelegate: HomeViewModelCoordinatorDelegate?

    let dataManager: HomeViewModelDataManager

    let stations = Binding<[BikeStation]>(value: [])

    let stationsDict = Binding<[String: BikeStation]>(value: [:])

    func getCurrentCity(completion: @escaping(Result<City>) -> Void) {

        dataManager.getCurrentCity(completion: { cityResult in
            switch cityResult {

            case .success(let city):
                let centerCoordinates = CLLocationCoordinate2D(latitude: CLLocationDegrees(city.latitude), longitude: CLLocationDegrees(city.longitude))

                self.delegate?.centerMap(on: centerCoordinates)

            case .error(let err):
                print("ERROR \(err)")
            }
        })
    }

    func removeAnnotationsFromMap() {

        delegate?.removePinsFromMap()
    }

    init(city: City?, compositeDisposable: CompositeDisposable, dataManager: HomeViewModelDataManager) {

        self.city = city
        self.compositeDisposable = compositeDisposable
        self.dataManager = dataManager

        LocationServices.sharedInstance.delegate = self
        LocationServices.sharedInstance.locationManager?.requestWhenInUseAuthorization()
        LocationServices.sharedInstance.locationManager?.startUpdatingLocation()

        if let currentCity = self.city {

            dataManager.getStations(city: currentCity.formalName, completion: {resultStations in

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
    }

    func getApiData(city: String, type: String, station: String, prediction: Bool) {

        dataManager.getPredictionForStation(city: city, type: type, name: station, completion: { [weak self] res in

            guard let self = self else { fatalError() }

            if let datos = res {

                let sortedKeysAndValues = Array(datos.values).sorted(by: { $0.0 < $1.0 })

                var datosa: [Int] = []

                sortedKeysAndValues.forEach({ datosa.append($0.value )})

                self.delegate?.drawPrediction(data: datosa, prediction: prediction)

            }
        })
    }
}

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
    func didTapRestart()
    func showSettingsViewController()
    func modallyPresentRoutePlanner(stationsDict: [String:BikeStation])
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
    func presentAlertViewWithError(title: String, body: String)
    func updatePredictionStatus(imageString: String, nextHour: String)
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

    var currentPredictions = [Int]()
    var currentAvailability = [Int]()

    func modallyPresentRoutePlanner() {
        coordinatorDelegate?.modallyPresentRoutePlanner(stationsDict: self.stationsDict.value)
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

                dump(self.stationsDict)
                print()

                self.coordinatorDelegate?.modallyPresentRoutePlanner(stationsDict: self.stationsDict.value)

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

    let listHours = ["00:00","00:10","00:20","00:30","00:40","00:50","01:00","01:10","01:20","01:30","01:40","01:50","02:00","02:10","02:20","02:30","02:40","02:50","03:00","03:10","03:20","03:30","03:40","03:50","04:00","04:10","04:20","04:30","04:40","04:50","05:00","05:10","05:20","05:30","05:40","05:50","06:00","06:10","06:20","06:30","06:40","06:50","07:00","07:10","07:20","07:30","07:40","07:50","08:00","08:10","08:20","08:30","08:40","08:50","09:00","09:10","09:20","09:30","09:40","09:50","10:00","10:10","10:20","10:30","10:40","10:50","11:00","11:10","11:20","11:30","11:40","11:50","12:00","12:10","12:20","12:30","12:40","12:50","13:00","13:10","13:20","13:30","13:40","13:50","14:00","14:10","14:20","14:30","14:40","14:50","15:00","15:10","15:20","15:30","15:40","15:50","16:00","16:10","16:20","16:30","16:40","16:50","17:00","17:10","17:20","17:30","17:40","17:50","18:00","18:10","18:20","18:30","18:40","18:50","19:00","19:10","19:20","19:30","19:40","19:50","20:00","20:10","20:20","20:30","20:40","20:50","21:00","21:10","21:20","21:30","21:40","21:50","22:00","22:10","22:20","22:30","22:40","22:50","23:00","23:10","23:20","23:30","23:40","23:50"]

    func getApiData(city: String, type: String, station: String, prediction: Bool, completion: @escaping(Result<[Int]>) -> Void) {

        dataManager.getPredictionForStation(city: city, type: type, name: station, completion: { [weak self] res in

            guard let self = self else { fatalError() }

            if let datos = res {

                let sortedKeysAndValues = Array(datos.values).sorted(by: { $0.0 < $1.0 })

                var datosa: [Int] = []

                sortedKeysAndValues.forEach({ datosa.append($0.value )})

                // Get the remainder values for the prediction

                if prediction {
                    self.currentPredictions = datosa
                } else if !prediction {
                    self.currentAvailability = datosa
                }

                if self.currentAvailability.count > 0 && self.currentPredictions.count > 0 {
                    let remainderPredictionOfTheDay = self.currentPredictions[(self.currentAvailability.count)...]
                    print(remainderPredictionOfTheDay.count)

                    let timeStationWillBeEmpty = remainderPredictionOfTheDay.firstIndex(of: 0)

                    if timeStationWillBeEmpty != nil {
                        print("[\(self.listHours[self.currentAvailability.count])] Station will be empty at \(self.listHours[timeStationWillBeEmpty!])")
                        print()

                        self.delegate?.updatePredictionStatus(imageString: "0.fill", nextHour: self.listHours[timeStationWillBeEmpty!])
                    }
                }

                self.delegate?.drawPrediction(data: datosa, prediction: prediction)

                completion(.success(datosa))

            }
        })
    }
}

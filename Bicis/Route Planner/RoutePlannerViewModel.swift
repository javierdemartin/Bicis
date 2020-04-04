//
//  RoutePlannerViewModel.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 09/03/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import ReactiveSwift
import MapKit

protocol RoutePlannerViewModelCoordinatorDelegate: class {
//    func sendSelectedDestinationToHomeViewController(station: BikeStation)
    func dismissModalRoutePlannerViewController()
}

protocol RoutePlannerViewModelDelegate: class {
//    func selectedDestination(station: BikeStation)
    func presentAlertViewWithError(title: String, body: String)
//    func gotRouteCalculations(route: MKRoute)
    func errorTooFarAway()
    func gotDestinationRoute(station: BikeStation, route: MKRoute)
}

protocol RoutePlannerViewModelDataManager: class {
    func getPredictionForStation(city: String, type: String, name: String, completion: @escaping(Result<MyAPIResponse>) -> Void)
    func getCurrentCity(completion: @escaping (Result<City>) -> Void)
}

class RoutePlannerViewModel: NSObject {

    let compositeDisposable: CompositeDisposable
    let stationsDict: [String: BikeStation]?
    weak var coordinatorDelegate: RoutePlannerViewModelCoordinatorDelegate?
    weak var delegate: RoutePlannerViewModelDelegate?

    var destinationRoute = MKRoute()
    var destinationStation = Binding<BikeStation?>(value: nil)

    let dataManager: RoutePlannerViewModelDataManager

    init(compositeDisposable: CompositeDisposable, dataManager: RoutePlannerViewModelDataManager, stationsDict: [String: BikeStation]?, destinationStation: BikeStation?) {

        self.compositeDisposable = compositeDisposable
        self.stationsDict = stationsDict

        self.dataManager = dataManager

        super.init()

        self.destinationStation.value = destinationStation
    }

    func drawDataWhateverImTired() {

        guard let station = destinationStation.value else { return }

        guard let location = LocationServices.sharedInstance.getLatestLocationCoordinates() else { return }

        self.calculateRouteToDestination(pickupCoordinate: location, destinationCoordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(station.latitude), longitude: CLLocationDegrees(station.longitude)), completion: { resultRoute in

            switch resultRoute {

            case .success(let route):
                self.delegate?.gotDestinationRoute(station: station, route: route)
            case .error(let err):
                dump(err)
                self.delegate?.errorTooFarAway()

            }
        })
    }

    func calculateRmseForStationByQueryingPredictions(completion: @escaping(()) -> Void) {

        guard self.destinationStation.value != nil else { return }

        dataManager.getCurrentCity(completion: { currentCityResult in

            switch currentCityResult {

            case .success(let city):

                var stationName = ""

                if city.apiName != "bilbao" {
                    stationName = self.destinationStation.value!.id
                } else {
                    stationName = self.destinationStation.value!.stationName
                }

                self.dataManager.getPredictionForStation(city: city.apiName, type: "prediction", name: stationName, completion: { predictionArray in

                    switch predictionArray {

                    case .success(let predictionArray):

                        let sortedKeysAndValues = Array(predictionArray.values).sorted(by: { $0.0 < $1.0 })

                        var predictionArrayFinal: [Int] = []

                        sortedKeysAndValues.forEach({ predictionArrayFinal.append($0.value )})

                        self.destinationStation.value!.predictionArray = predictionArrayFinal

                        self.dataManager.getPredictionForStation(city: city.apiName, type: "today", name: stationName, completion: { actualArrayResult in

                            switch actualArrayResult {

                            case .success(let actualArray):

                                let sortedKeysAndValues = Array(actualArray.values).sorted(by: { $0.0 < $1.0 })

                                var todayArrayFinal: [Int] = []

                                sortedKeysAndValues.forEach({ todayArrayFinal.append($0.value )})

                                self.destinationStation.value!.availabilityArray = todayArrayFinal

                                completion(())
                            case .error(let err):
                                self.delegate?.presentAlertViewWithError(title: "Error", body: err.localizedDescription)
                            }

                        })
                    case .error(let error):
                        self.delegate?.presentAlertViewWithError(title: "Error", body: error.localizedDescription)
                    }

                })
            case .error:
                break
            }
        })

    }
}

extension RoutePlannerViewModel: MKMapViewDelegate {

    func calculateRouteToDestination(pickupCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D, completion: @escaping(Result<MKRoute>) -> Void) {

        let sourcePlacemark = MKPlacemark(coordinate: pickupCoordinate, addressDictionary: nil)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate, addressDictionary: nil)

        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)

        let sourceAnnotation = MKPointAnnotation()

        if let location = sourcePlacemark.location {
            sourceAnnotation.coordinate = location.coordinate
        }

        let destinationAnnotation = MKPointAnnotation()

        if let location = destinationPlacemark.location {
            destinationAnnotation.coordinate = location.coordinate
        }

        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .automobile

        // Calculate the direction
        let directions = MKDirections(request: directionRequest)

        directions.calculate { (response, error) -> Void in

            guard let response = response else {
                if let error = error {
                    dump(error)

                    return completion(.error(error))
                }

                return
            }

            self.destinationRoute = response.routes[0]

            completion(.success(self.destinationRoute))

        }
    }
}

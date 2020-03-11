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
import UserNotifications

protocol RoutePlannerViewModelCoordinatorDelegate: class {
    func sendSelectedDestinationToHomeViewController(station: BikeStation)
}

protocol RoutePlannerViewModelDelegate: class {
    func selectedDestination(station: BikeStation)
    func presentAlertViewWithError(title: String, body: String)
    func gotRouteCalculations(route: MKRoute)
}

protocol RoutePlannerViewModelDataManager: class {
    func getPredictionForStation(city: String, type: String, name: String, completion: @escaping(MyAPIResponse?) -> Void)
    func getCurrentCity(completion: @escaping (Result<City>) -> Void)
}

class RoutePlannerViewModel: NSObject {

    let compositeDisposable: CompositeDisposable
    let stationsDict: [String: BikeStation]
    weak var coordinatorDelegate: RoutePlannerViewModelCoordinatorDelegate?
    weak var delegate: RoutePlannerViewModelDelegate?

    var destinationRoute = MKRoute()
    var destinationStation: BikeStation?

    let dataManager: RoutePlannerViewModelDataManager

    init(compositeDisposable: CompositeDisposable, dataManager: RoutePlannerViewModelDataManager, stationsDict: [String: BikeStation]) {

        self.compositeDisposable = compositeDisposable
        self.stationsDict = stationsDict

        self.dataManager = dataManager
    }

    func checkUserNotificationStatus() {

        let userNotificationCenter = UNUserNotificationCenter.current()

        let authOptions = UNAuthorizationOptions.init(arrayLiteral: .alert, .badge, .sound)

        userNotificationCenter.requestAuthorization(options: authOptions) { (success, error) in
            if let error = error {
                print("Error: ", error)
            }

            if success {
                print("Starting timer!")
                RoutePlannerTimerServices.sharedInstance.startTimer()
            }
        }
    }

    func selectedDestinationStation(name: String) {
        guard let destinationStation = stationsDict[name] else { return }

        self.destinationStation = destinationStation

        // If no location is retrieved don't show the route in the map
        guard let userLocation = LocationServices.sharedInstance.locationManager?.location?.coordinate else { return }

        // TODO: Delete force unwrap
        calculateRouteToDestination(pickupCoordinate: userLocation, destinationCoordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(destinationStation.latitude), longitude: CLLocationDegrees(destinationStation.longitude)))

        coordinatorDelegate?.sendSelectedDestinationToHomeViewController(station: destinationStation)
    }

    func calculateRmseForStationByQueryingPredictions(completion: @escaping(Void) -> Void) {

        guard destinationStation != nil else { return }

        dataManager.getCurrentCity(completion: { currentCityResult in

            switch currentCityResult {

            case .success(let city):

                var stationName = ""

                if city.apiName != "bilbao" {
                    stationName = self.destinationStation!.id
                } else {
                    stationName = self.destinationStation!.stationName
                }

                self.dataManager.getPredictionForStation(city: city.apiName, type: "prediction", name: stationName, completion: { predictionArray in

                    guard predictionArray != nil else { return }

                    let sortedKeysAndValues = Array(predictionArray!.values).sorted(by: { $0.0 < $1.0 })

                    var predictionArrayFinal: [Int] = []

                    sortedKeysAndValues.forEach({ predictionArrayFinal.append($0.value )})

                    self.destinationStation!.predictionArray = predictionArrayFinal

                    self.dataManager.getPredictionForStation(city: city.apiName, type: "today", name: stationName, completion: { actualArray in

                        guard actualArray != nil else { return }

                        let sortedKeysAndValues = Array(actualArray!.values).sorted(by: { $0.0 < $1.0 })

                        var todayArrayFinal: [Int] = []

                        sortedKeysAndValues.forEach({ todayArrayFinal.append($0.value )})

                        self.destinationStation!.availabilityArray = todayArrayFinal

                        completion(())
                    })
                })
            case .error:
                break
            }
        })

    }
}

extension RoutePlannerViewModel: MKMapViewDelegate {

    func calculateRouteToDestination(pickupCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D) {

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
                    print("Error: \(error)")
                }

                return
            }

            self.destinationRoute = response.routes[0]

            guard self.destinationStation != nil else { return }

            self.delegate?.gotRouteCalculations(route: self.destinationRoute)

        }
    }
}

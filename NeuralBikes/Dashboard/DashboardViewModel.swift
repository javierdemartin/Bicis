//
//  RoutePlannerViewModel.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 09/03/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import MapKit
import Combine

protocol DashboardViewModelDelegate: class {
    func presentAlertViewWithError(title: String, body: String)
    func errorTooFarAway()
    func updateBikeStationOperations(nextRefill: String?, nextDischarge: String?)
    func fillClosestStationInformation(station: BikeStation)
    func showMostUsedStations(stations: [String: Int])
}

protocol DashboardViewModelDataManager: class {
    func getPredictionForStation(city: String, type: String, name: String, completion: @escaping(Result<MyAPIResponse>) -> Void)
    func getCurrentCity(completion: @escaping (Result<City>) -> Void)
    func getStationStatistics(for city: String) -> [String: Int]
    func getAllDataFromApi(city: String, station: String, completion: @escaping(Result<NeuralBikeAllAPIResponse>) -> Void)
    func getPredictedNumberOfDocksAt(time: String, for station: BikeStation, completion: @escaping(Result<Int>) -> Void)
}

class DashboardViewModel: NSObject, ObservableObject, Identifiable {
    
    @Published var destinationStationString: String = ""
    @Published var nextRefillTime: String?
    @Published var nextDischargeTime: String?
    @Published var predictionPrecission: String?
    @Published var expectedArrivalTime: String = "-:--"
    @Published var expectedDocksAtArrivalTime: String = "-"
    @Published var actualDocksAtDestination: String = "-"
    
    @Published var predictionArray: [Int] = []
    @Published var availabilityArray: [Int] = []
    
    @Published var numberOfTimesLaunched: String = ""

    let stationsDict: [String: BikeStation]? = [:]
    weak var delegate: DashboardViewModelDelegate?
    let dateFormatter = DateFormatter()
    let locationService: LocationServiceable
    var predictionJson: [String: Int] = [:]
    
    @Published var stations : [BikeStation]

    @Published var destinationStation: BikeStation? = nil
    
    var freeStations: [String] {
        get {
            return self.stations.filter({ $0.freeBikes == 0}).map({ $0.stationName })
        }
    }
    
    var fullStations: [String] {
        get {
            return self.stations.filter({ $0.freeRacks == 0}).map({ $0.stationName })
        }
    }
    
    var totalFreeBikes: Int {
        get {
            return self.stations.map({ $0.freeBikes }).reduce(0, +)
        }
    }
    
    var totalFreeRacks: Int {
        get {
            return self.stations.map({ $0.freeRacks + $0.freeBikes }).reduce(0, +)
        }
    }
    
    // Load factor = bikes available / # docks
    var loadFactor: Int {
        get {
            return Int(Double(totalFreeBikes) / Double(totalFreeRacks) * 100)
        }
    }
    
    let dataManager: DashboardViewModelDataManager

    init(locationService: LocationServiceable, dataManager: DashboardViewModelDataManager, destinationStation: BikeStation, stations: [BikeStation]) {

        self.dataManager = dataManager
        
        self.locationService = locationService
        
        self.destinationStation = destinationStation
        self.stations = stations
        
        print("Total free bikes \(stations.map({ $0.freeBikes }).reduce(0, +))")
        print("Total free racks \(stations.map({ $0.freeRacks }).reduce(0, +))")
        
        destinationStationString = destinationStation.stationName
        
        if let precission = destinationStation.rmse {
            predictionPrecission = NSLocalizedString("ACCURACY_OF_MODEL", comment: "").replacingOccurrences(of: "%percentage%", with: "\(Int(precission))%")
        }
        
        super.init()
        
        setUpLocation()
        
        drawGraph()
        
        guard let numberOfTimesLaunchedUnwrapped = StoreKitHelper.getNumberOfTimesLaunched() else {
            return
        }
        
        guard let app_name = Bundle.main.infoDictionary!["CFBundleName"] as? String else { return }
        
        numberOfTimesLaunched = NSLocalizedString("NUMBER_TIMES_LAUNCHED", comment: "").replacingOccurrences(of: "%app_name%", with: app_name).replacingOccurrences(of: "%times%", with: "\(numberOfTimesLaunchedUnwrapped)")
        
        print(numberOfTimesLaunched)
    }
    
    func setUpLocation() {
            switch locationService.getPermissionStatus() {
            case .granted:
                locationService.startMonitoring()
                
                guard let latestLocation = locationService.currentLocation else { return }
                
                guard let destinationStation = destinationStation else { return }
                
                self.calculateRouteToDestination(pickupCoordinate: latestLocation.coordinate, destinationCoordinate: destinationStation.location.coordinate, completion: { result in
                    
                    switch result {
                        
                    case .success(let arrivalTime):
                        self.expectedArrivalTime = arrivalTime
                        
                        guard let expectedDocks = self.getPredictedDocksForArrivalTime(time: arrivalTime) else { return }
                        
                        self.expectedDocksAtArrivalTime = "\(expectedDocks)"
                        
                    case .error(let error):
                        dump(error)
                    }
                })
                
            case .denied:
                break
            case .notDetermined:
                locationService.requestPermissions()
            }
        }
    
    func getPredictedDocksForArrivalTime(time: String) -> Int? {
        
        if let actualDocks = self.destinationStation?.freeRacks {
            self.actualDocksAtDestination = "\(actualDocks)"
        }
        
        guard self.destinationStation != nil else { return nil }
        
        var time = time
        time.removeLast()
        time += "0"
        
        var numberOfDocksAtTime: Int?
        
        dataManager.getPredictedNumberOfDocksAt(time: time, for: destinationStation!, completion: { result in
            
            switch result {
            case .success(let numberOfDocks):
                numberOfDocksAtTime = numberOfDocks
                self.expectedDocksAtArrivalTime = "\(numberOfDocks)"
            case .error:
                break
            }
        })
        
        return numberOfDocksAtTime
    }
        
    deinit {
        
    }
    
    func drawGraph() {
        
        // Date retrieved from the API uses 24 hour formand intependently of the user's locale
        dateFormatter.dateFormat = "HH:mm"
        
        let date = Date()
        let calendar = Calendar.current
        
        dataManager.getCurrentCity(completion: { currentCityResult in

            switch currentCityResult {

            case .success(let city):

                var stationName = ""

                stationName = self.destinationStation!.id

                self.dataManager.getAllDataFromApi(city: city.apiName, station: stationName, completion: { result in

                    switch result {

                    case .success(let datos):
                        
                        self.predictionJson = datos.values.prediction

                        let sortedNowKeysAndValues = Array(datos.values.today).sorted(by: { $0.0 < $1.0 })
                        let sortedPredictionKeysAndValues = Array(datos.values.prediction).sorted(by: { $0.0 < $1.0 })

                        var sortedNow: [Int] = []
                        var sortedPrediction: [Int] = []

                        sortedNowKeysAndValues.forEach({ sortedNow.append($0.value )})
                        sortedPredictionKeysAndValues.forEach({ sortedPrediction.append($0.value )})

                        self.destinationStation!.availabilityArray = sortedNow
                        self.destinationStation!.predictionArray = sortedPrediction
                        
                        self.predictionArray = sortedPrediction
                        self.availabilityArray = sortedNow
                        
                        // Get local time
                        let closestNextRefillTime = datos.refill.reversed().first(where: {
                            calendar.component(.hour, from: date) < calendar.component(.hour, from: self.dateFormatter.date(from: $0)!)
                        })

                        let closestNextDischargeTime = datos.discharges.reversed().first(where: {
                            calendar.component(.hour, from: self.dateFormatter.date(from: $0)!) < calendar.component(.hour, from: date)
                        })

                        // Fill refill/discharge times for the station
                        self.nextRefillTime = closestNextRefillTime ?? NSLocalizedString("NOT_FOUND", comment: "")
                        self.nextDischargeTime = closestNextDischargeTime ?? NSLocalizedString("NOT_FOUND", comment: "")
                        
                    case .error:
                        break
                    }
                })

            case .error:
                break
            }
        })
    }

    func calculateRmseForStationByQueryingPredictions(completion: @escaping(()) -> Void) {

        // Date retrieved from the API uses 24 hour formand intependently of the user's locale
        dateFormatter.dateFormat = "HH:mm"

        guard self.destinationStation != nil else { return }

        let date = Date()
        let calendar = Calendar.current

        dataManager.getCurrentCity(completion: { currentCityResult in

            switch currentCityResult {

            case .success(let city):

                var stationName = ""

                stationName = self.destinationStation!.id

                self.dataManager.getAllDataFromApi(city: city.apiName, station: stationName, completion: { result in

                    switch result {

                    case .success(let datos):
                        
                        self.predictionJson = datos.values.prediction

                        let sortedNowKeysAndValues = Array(datos.values.today).sorted(by: { $0.0 < $1.0 })
                        let sortedPredictionKeysAndValues = Array(datos.values.prediction).sorted(by: { $0.0 < $1.0 })

                        var sortedNow: [Int] = []
                        var sortedPrediction: [Int] = []

                        sortedNowKeysAndValues.forEach({ sortedNow.append($0.value )})
                        sortedPredictionKeysAndValues.forEach({ sortedPrediction.append($0.value )})

                        self.destinationStation!.availabilityArray = sortedNow
                        self.destinationStation!.predictionArray = sortedPrediction
                        
                        self.predictionArray = sortedPrediction
                        self.availabilityArray = sortedNow

                        // Get local time
                        let closestNextRefillTime = datos.refill.reversed().first(where: {
                            calendar.component(.hour, from: date) < calendar.component(.hour, from: self.dateFormatter.date(from: $0)!)
                        })

                        let closestNextDischargeTime = datos.discharges.reversed().first(where: {
                            calendar.component(.hour, from: self.dateFormatter.date(from: $0)!) < calendar.component(.hour, from: date)
                        })

                        // Fill refill/discharge times for the station
                        self.nextRefillTime = closestNextRefillTime
                        self.nextDischargeTime = closestNextDischargeTime
                        self.delegate?.updateBikeStationOperations(nextRefill: closestNextRefillTime, nextDischarge: closestNextDischargeTime)

                        completion(())
                    case .error:
                        break
                    }
                })

            case .error:
                break
            }
        })
    }
    
    func calculateRouteToDestination(pickupCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D, completion: @escaping(Result<String>) -> Void) {

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
                    return completion(.error(error))
                }

                return
            }

            let destinationRoute = response.routes[0]
                        
            let calendar = Calendar.current
            let date = calendar.date(byAdding: .second, value: Int(destinationRoute.expectedTravelTime), to: Date())

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            let roundedArrivalTime = dateFormatter.string(from: date!)

            let formatter = MeasurementFormatter()
            formatter.unitOptions = .naturalScale
            formatter.unitStyle = .short
            formatter.locale = Locale(identifier: Locale.current.languageCode!)

            completion(.success(roundedArrivalTime))

        }
    }

}

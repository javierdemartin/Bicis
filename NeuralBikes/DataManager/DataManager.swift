//
//  DataManager.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 02/11/2019.
//  Copyright © 2019 Javier de Martín Gil. All rights reserved.
//

import Foundation

class DataManager {

    let localDataManager: LocalDataManager
    let remoteDataManager: RemoteDataManager

    init(localDataManager: LocalDataManager, remoteDataManager: RemoteDataManager) {
        self.localDataManager = localDataManager
        self.remoteDataManager = remoteDataManager
    }
}

// MARK: HomeViewModelDataManager
extension DataManager: HomeViewModelDataManager {
    
    func addStationStatistics(for id: String, city: String) {
        localDataManager.addStationStatistics(for: id, city: city)
    }
    
    func getCurrentCity(completion: @escaping (Result<City>) -> Void) {
        localDataManager.getCurrentCity(completion: { getCurrentCityResult in
            switch getCurrentCityResult {

            case .success(let res):
                completion(.success(res))
            case .error(let err):
                completion(.error(err))
            }
        })
    }

    func getStations(city: String, completion: @escaping (Result<[BikeStation]>) -> Void) {
        remoteDataManager.getStations(city: city, completion: { res in
            completion(res)
        })
    }

    func getAllDataFromApi(city: String, station: String, completion: @escaping (Result<MyAllAPIResponse>) -> Void) {

        localDataManager.addStationStatistics(for: station, city: city)

        remoteDataManager.getAllDataFromApi(city: city, station: station, completion: { res in
            completion(res)
        })
    }
}

// MARK: RoutePlannerViewModelDataManager
extension DataManager: InsightsViewModelDataManager {
    
    func getPredictedNumberOfDocksAt(time: String, for station: BikeStation, completion: @escaping(Result<Int>) -> Void) {
        
        localDataManager.getCurrentCity(completion: { cityResult in
            
            switch cityResult {
                
            case .success(let city):
                self.remoteDataManager.getAllDataFromApi(city: city.apiUrl, station: station.id, completion: { allDataResult in
                    
                    switch allDataResult {
                        
                    case .success(let data):
                        
                        guard let expectedBikesAtArrival = data.values.prediction[time] else { break }
                        
                        guard let maxAvailability = data.values.today.values.max(), let maxPrediction = data.values.prediction.values.max() else {
                            
                            completion(.success(-1))
                            return
                        }
                        
                        let maxDocks = max(maxAvailability, maxPrediction)
                        
                        completion(.success(maxDocks - expectedBikesAtArrival))

                    case .error(let error):
                        completion(.error(error))
                    }
                })
            case .error(let error):
                completion(.error(error))
            }
        })
    }
    
    func getStationStatistics(for city: String) -> [String: Int] {
        return localDataManager.getStationStatistics(for: city)
    }

    func getPredictionForStation(city: String, type: String, name: String, completion: @escaping (Result<MyAPIResponse>) -> Void) {
        
        localDataManager.addStationStatistics(for: name, city: city)
        
        remoteDataManager.getPredictionForStation(city: city, type: type, name: name, completion: { res in
            completion(res)
        })
    }
}

// MARK: SettingsViewModelDataManager
extension DataManager: SettingsViewModelDataManager {

    func getCurrentCityFromDefaults(completion: @escaping (Result<City>) -> Void) {
        localDataManager.getCurrentCity(completion: { cityResult in

            switch cityResult {

            case .success(let city):
                completion(.success(city))
            case .error(let err):
                completion(.error(err))
            }
        })
    }

    func saveCurrentCity(apiCityName: City, completion: @escaping (Result<Void>) -> Void) {
        localDataManager.saveCurrentCity(apiCityName: apiCityName, completion: { saveCurrentCityResult in
            switch saveCurrentCityResult {
            case .success:
                completion(.success(()))
            case .error(let err):
                completion(.error(err))
            }
        })
    }
}

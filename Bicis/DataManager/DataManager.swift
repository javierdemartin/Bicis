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

extension DataManager: HomeViewModelDataManager {

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

    func checkUserCredentials(completion: @escaping (Result<UserCredentials>) -> Void) {

        localDataManager.getUserData(completion: { userDataResult in

            completion(userDataResult)
        })
    }

    func getStations(city: String, completion: @escaping (Result<[BikeStation]>) -> Void) {
        remoteDataManager.getStations(city: city, completion: { res in

            completion(res)
        })
    }

    func getPredictionForStation(city: String, type: String, name: String, completion: @escaping (MyAPIResponse?) -> Void) {
        remoteDataManager.getPredictionForStation(city: city, type: type, name: name, completion: { res in
            completion(res)
        })
    }
}

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
                // TODO: Implementar gestión de error
                completion(.error(err))
            }
        })
    }
}

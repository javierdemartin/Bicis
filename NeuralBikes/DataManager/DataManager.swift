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
    let bikeServicesDataManager: BikeServicesDataManager

    init(localDataManager: LocalDataManager, remoteDataManager: RemoteDataManager, bikeServicesDataManager: BikeServicesDataManager) {
        self.localDataManager = localDataManager
        self.remoteDataManager = remoteDataManager
        self.bikeServicesDataManager = bikeServicesDataManager
    }
}

// MARK: LogInViewModelDataManager

extension DataManager: LogInViewModelDataManager {
    func logIn(with userCredentials: UserCredentials, completion: @escaping(Result<LogInResponse>) -> Void) {
        
        bikeServicesDataManager.logIn(credentials: userCredentials, completion: { logInResult in
            
            switch logInResult {
                 
            case .success(let logInResponse):
                
                guard let userResponse = logInResponse.user else { return }
                
                self.localDataManager.saveUserData(validateInstallationResponse: userCredentials, completion: { _ in
                    self.localDataManager.saveLogIn(response: userResponse)
                })
                
            case .error(let error):
                print(error)
            }
        })
    }
}

// MARK: HomeViewModelDataManager
extension DataManager: HomeViewModelDataManager {
    func isUserLoggedIn(completion: @escaping (Result<LogInResponse>) -> Void) {
                
        localDataManager.getUserData(completion: { userCredentialsResult in
            
            switch userCredentialsResult {
            case .success(let userCredentials):
                self.bikeServicesDataManager.isUserLoggedIn(credentials: userCredentials, completion: { result in
                    
                    switch result {
                        
                    case .success(let loginApiResponse):
                        completion(.success(loginApiResponse))
                    case .error(let error):
                        completion(.error(error))
                    }
                    
                })
            case .error(let error):
                completion(.error(error))
            }
        })
    }
    
    func getActiveRentals(completion: @escaping(Result<GetActiveRentalsResponse>) -> Void) {
                
        isUserLoggedIn(completion: { logInResponse in
            switch logInResponse {
                
            case .success(let logIn):
                
                guard let logInKey = logIn.user?.loginkey else {
                    completion(.error(BikeServicesDataManagerError.couldntGetLogInKey))
                    return
                }
                
                self.bikeServicesDataManager.getApiKey(completion: { apiKeyResult in
                    switch apiKeyResult {
                        
                    case .success(let apiKey):
                        self.bikeServicesDataManager.getActiveRentals(apiKey: apiKey.apiKey, logInKey: logInKey, completion: { rentalsResponse in
                            switch rentalsResponse {
                                
                            case .success(let activeRentals):
                                completion(.success(activeRentals))
                            case .error(let error):
                                completion(.error(error))
                            }
                        })
                    case .error(let error):
                        completion(.error(error))
                    }
                })
            case .error(let error):
                completion(.error(error))
            }
        })
    }
    
    func rent(bike number: Int, completion: @escaping(Result<Void>) -> Void) {
        
        isUserLoggedIn(completion: { logInResponse in
            switch logInResponse {
                
            case .success(let logIn):
                self.bikeServicesDataManager.rent(loginKey: logIn.user!.loginkey, bike: number, completion: { rentResult in
                    
                    switch rentResult {
                        
                    case .success():
                        completion(.success(()))
                    case .error(let error):
                        completion(.error(error))
                    }
                })
            case .error(let error):
                completion(.error(error))
            }
        })
    }
    
    func addStationStatistics(for id: String, city: String) {
        localDataManager.addStationStatistics(for: id, city: city)
    }

    func hasUnlockedFeatures(completion: @escaping (Result<Bool>) -> Void) {
        localDataManager.hasUnlockedFeatures(completion: { hasUnlockedResult in
            completion(hasUnlockedResult)
        })
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

    func getAllDataFromApi(city: String, station: String, completion: @escaping (Result<MyAllAPIResponse>) -> Void) {

        localDataManager.addStationStatistics(for: station, city: city)

        remoteDataManager.getAllDataFromApi(city: city, station: station, completion: { res in
            completion(res)
        })
    }
}

// MARK: RoutePlannerViewModelDataManager
extension DataManager: InsightsViewModelDataManager {
    func getStationStatistics(for city: String) -> [String : Int] {
        return localDataManager.getStationStatistics(for: city)
    }

    func getPredictionForStation(city: String, type: String, name: String, completion: @escaping (Result<MyAPIResponse>) -> Void) {
        remoteDataManager.getPredictionForStation(city: city, type: type, name: name, completion: { res in
            completion(res)
        })
    }
}

// MARK: SettingsViewModelDataManager
extension DataManager: SettingsViewModelDataManager {
    func logOut() {
        localDataManager.logOut()
    }

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

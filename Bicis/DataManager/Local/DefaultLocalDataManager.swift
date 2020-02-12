//
//  DefaultLocalDataManager.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 03/11/2019.
//  Copyright © 2019 Javier de Martín Gil. All rights reserved.
//

import Foundation

class DefaultLocalDataManager: LocalDataManager {

    let defaults = UserDefaults(suiteName: Constants.appGroupsBundleID)!

    func saveCurrentCity(apiCityName: City, completion: @escaping (Result<Void>) -> Void) {

        do {
            let encodedData = try PropertyListEncoder().encode(apiCityName)
            defaults.set(encodedData, forKey: "city")

            completion(.success(()))

        } catch {
            completion(.error(LocalDataManagerError.errorSavingToDefaults))
        }
    }

    func getCurrentCity(completion: @escaping (Result<City>) -> Void) {

        guard let data = defaults.value(forKey: "city") as? Data else {
            completion(.error(LocalDataManagerError.noCitySaved))
           return
        }

        guard let decoded = try? PropertyListDecoder().decode(City.self, from: data) else {
            completion(.error(LocalDataManagerError.errorDecodingDefaults))
           return
        }

        completion(.success(decoded))
    }

    func saveUserData(validateInstallationResponse: UserCredentials, completion: @escaping (Result<Void>) -> Void) {
        do {
            let encodedData = try PropertyListEncoder().encode(validateInstallationResponse)
            defaults.set(encodedData, forKey: "UserCredentials")

            completion(.success(()))

        } catch {
            completion(.error(LocalDataManagerError.errorSavingToDefaults))
        }
    }

    func getUserData(completion: @escaping (Result<UserCredentials>) -> Void) {

        guard let data = defaults.value(forKey: "UserCredentials") as? Data else {
            completion(.error(LocalDataManagerError.noLogInSaved))
           return
        }

        guard let decoded = try? PropertyListDecoder().decode(UserCredentials.self, from: data) else {
            completion(.error(LocalDataManagerError.errorDecodingDefaults))
           return
        }

        completion(.success(decoded))
    }
}

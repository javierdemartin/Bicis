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

    func getStationStatistics(for city: String) -> [String: Int] {

//        if let data = defaults.value(forKey: Constants.selectedStationsStatistics) as? Data {
//
//            let unwrapped = try? PropertyListDecoder().decode(StationStatistics.self, from: data)
//
//            guard let unwr = unwrapped else {
//                return [:]
//            }
//
//            guard let unwra = unwr.statistics[city] else {
//                return [:]
//            }
//
//            return unwra
//        } else {
//            return [:]
//        }

        return [:]
    }

    func addStationStatistics(for id: String, city: String) {

        let hour = Calendar.current.component(.hour, from: Date())

        if let data = defaults.value(forKey: Constants.selectedStationsStatistics) as? Data {
            var unwrapped = try? PropertyListDecoder().decode(StationStatistics.self, from: data)

            guard unwrapped != nil else {
                return
            }

            // If the station is present update the value
            if let cityIndex = unwrapped!.statistics.firstIndex(where: { $0.city == city }) {

                // Find the station's index
                if let stationIndex = unwrapped!.statistics[cityIndex].stations.firstIndex(where: { $0.stationId == id }) {

                    unwrapped!.statistics[cityIndex].stations[stationIndex].count += 1
                    unwrapped!.statistics[cityIndex].stations[stationIndex].timeOfDay.append(hour)

                }

                // This station has not been previously registered
                else {
                    unwrapped!.statistics[cityIndex].stations.append(StationStatisticsStation(stationId: id, count: 1, timeOfDay: [hour]))
                }
            }

            // New city
            else {
                unwrapped!.statistics.append(StationStatisticsItem(city: city, stations: [StationStatisticsStation(stationId: id, count: 1, timeOfDay: [hour])]))
            }

            // Save the updated data into defaults
            defaults.set(try? PropertyListEncoder().encode(unwrapped!), forKey: Constants.selectedStationsStatistics)
//            print("he")

        } else {
            print("No data")
            let stationStatistics = StationStatistics(statistics: [StationStatisticsItem(city: city, stations: [StationStatisticsStation(stationId: id, count: 1, timeOfDay: [hour])])])
            dump(stationStatistics)

            defaults.set(try? PropertyListEncoder().encode(stationStatistics), forKey: Constants.selectedStationsStatistics)
        }
    }

    /// Reads the UserDefault bool value
    func hasUnlockedFeatures(completion: @escaping (Result<Bool>) -> Void) {

        // Automatically unlock the purchases if doing UI Tests, mainly to
        // facilitate fastlane's snapshot
        if UITestingHelper.sharedInstance.isUITesting() {
            completion(.success(true))
        }

        let hasPaidBefore = defaults.bool(forKey: StoreKitProducts.DataInsights)

        completion(.success(hasPaidBefore))
    }

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

//
//  LocalDataManager.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 02/11/2019.
//  Copyright © 2019 Javier de Martín Gil. All rights reserved.
//

import Foundation

protocol LocalDataManager {
    func saveUserData(validateInstallationResponse: UserCredentials, completion: @escaping (Result<Void>) -> Void)
    func getUserData(completion: @escaping (Result<UserCredentials>) -> Void)
    func saveCurrentCity(apiCityName: City, completion: @escaping (Result<Void>) -> Void)
    func getCurrentCity(completion: @escaping (Result<City>) -> Void)
    func hasUnlockedFeatures(completion: @escaping (Result<Bool>) -> Void)
    func addStationStatistics(for id: String, city: String)
    func getStationStatistics(for city: String) -> [String: Int]
    func saveLogIn(response: UserR)
    func logOut()
    func set<T>(value: T, for key: String)
}

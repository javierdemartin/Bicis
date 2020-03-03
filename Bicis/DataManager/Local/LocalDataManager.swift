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
}
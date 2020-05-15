//
//  BikeServicesDataManager.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 27/04/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation

protocol BikeServicesDataManager {
    
    var urlComponents: URLComponents { get set }
    
    func getApiKey(completion: @escaping (Result<Key>) -> Void)
    func isUserLoggedIn(credentials: UserCredentials, completion: @escaping (Result<LogInResponse>) -> Void)
    func logIn(credentials: UserCredentials, completion: @escaping(Result<LogInResponse>) -> Void)
    func rent(loginKey: String, bike number: Int, completion: @escaping(Result<Void>) -> Void)
    func getActiveRentals(apiKey: String, logInKey: String, completion: @escaping(Result<GetActiveRentalsResponse>) -> Void)
}

enum BikeServicesDataManagerError: Error {
    case errorDecodingApiKey
    case incorrectCredentials
    case couldntGetLogInKey
}

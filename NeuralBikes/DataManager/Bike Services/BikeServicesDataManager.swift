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
    func isUserLoggedIn(credentials: UserCredentials, completion: @escaping (Result<()>) -> Void)
    func logIn(credentials: UserCredentials, completion: @escaping(Result<LogInResponse>) -> Void)
}

enum BikeServicesDataManagerError: Error {
    case errorDecodingApiKey
    case incorrectCredentials
}

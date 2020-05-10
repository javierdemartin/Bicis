//
//  BikeServicesDataManager.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 27/04/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation

protocol BikeServicesDataManager {
    func getApiKey(completion: @escaping (Result<Key>) -> String)
}

enum BikeServicesDataManagerError: Error {
    case errorDecodingApiKey
}

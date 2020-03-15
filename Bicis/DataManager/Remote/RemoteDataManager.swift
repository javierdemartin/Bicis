//
//  RemoteDataManager.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 02/11/2019.
//  Copyright © 2019 Javier de Martín Gil. All rights reserved.
//

import Foundation

enum RemoteDataManagerError: Error {
    case incorrectLogInCredentials
    case couldntGetApiKey
    case noDataFromServer
    case couldntParseFeed
    case couldntGetApiKeyFromBiciMad
    case didNotGetAnyStation
    case errorParsingNeuralBikesApi
}

protocol RemoteDataManager {
    func getStations(city: String, completion: @escaping (Result<[BikeStation]>) -> Void)
    func getPredictionForStation(city: String, type: String, name: String, completion: @escaping(Result<MyAPIResponse>) -> Void)
}

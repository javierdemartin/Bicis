//
//  BikeServicesError.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 14/05/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation

enum BikeServicesError: Error {
    case bikeNotFound
}

extension BikeServicesError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .bikeNotFound:
            return "BIKE_NOT_FOUND".localize(file: "DataManager")
        }
    }
}

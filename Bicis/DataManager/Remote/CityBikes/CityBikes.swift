//
//  NewYorkParser.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 05/02/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation

protocol BikeStation: Decodable {
    var id: String { get set }
    var freeBikes: Int { get set }
    var stationName: String { get set }
    var latitude: Double { get set}
    var longitude: Double { get set}
}

struct CityBikesStation: BikeStation {
    var latitude: Double
    var longitude: Double
    var stationName: String
    var id: String
    var freeBikes: Int

    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case stationName = "name"
        case id
        case freeBikes = "free_bikes"
    }
}

struct CityBikesRoot: Decodable {
    let network: CityBikesStations
}

struct CityBikesStations: Decodable {
    let stations: [CityBikesStation]
}

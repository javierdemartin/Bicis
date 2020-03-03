//
//  Cities.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 23/01/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import CoreLocation

struct City: Codable {
    var apiName: String
    var formalName: String
    var latitude: Double
    var longitude: Double
    var apiUrl: String
}

var availableCities: [String: City] = [
    "New York": City(apiName: "new_york",
                     formalName: "New York",
                     latitude: 40.758896,
                     longitude: -73.985130,
                     apiUrl: "https://feeds.citibikenyc.com/stations/stations.json"),
    "Bilbao": City(apiName: "bilbao",
                   formalName: "Bilbao",
                   latitude: 43.263459,
                   longitude: -2.937053,
                   apiUrl: "https://nextbike.net/maps/nextbike-official.json?city=532"),
    "Madrid": City(apiName: "madrid",
                   formalName: "Madrid",
                   latitude: 40.416775,
                   longitude: -3.703790,
                   apiUrl: "https://openapi.emtmadrid.es/v1/transport/bicimad/stations/")
]

enum AvailableCities: String {
    case newYork = "New York"
    case bilbao = "Bilbao"
    case madrid = "Madrid"
}

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
    var allowsLogIn: Bool
}

var availableCities: [String: City] = [
    "New York": City(apiName: "new_york",
                     formalName: "New York",
                     latitude: 40.769320,
                     longitude: -73.969301,
                     apiUrl: "https://feeds.citibikenyc.com/stations/stations.json", allowsLogIn: false),
    "Bilbao": City(apiName: "bilbao",
                   formalName: "Bilbao",
                   latitude: 43.267427,
                   longitude: -2.937792,
                   apiUrl: "https://nextbike.net/maps/nextbike-official.json?city=532", allowsLogIn: false),
    "Madrid": City(apiName: "madrid",
                   formalName: "Madrid",
                   latitude: 40.419953,
                   longitude: -3.688479,
                   apiUrl: "https://openapi.emtmadrid.es/v1/transport/bicimad/stations/", allowsLogIn: false)
]

enum AvailableCities: String {
    case newYork = "New York"
    case bilbao = "Bilbao"
    case madrid = "Madrid"
}

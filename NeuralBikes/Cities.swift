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
    var logInCredentials: ApiPreLogIn?
    var gbfs: GBFS?
}

struct ApiPreLogIn: Codable {
    var url: String
    var username: String
    var password: String
    var apiKey: String
    var clientId: String
}

struct GBFS: Codable {
    
    var stationStatus: String
    var stationInformation: String
}

var availableCities: [String: City] = [
    "New York": City(apiName: "new_york",
                     formalName: "New York",
                     latitude: 40.769320,
                     longitude: -73.969301,
                     apiUrl: "https://gbfs.citibikenyc.com/gbfs/en/station_status.json",
                     allowsLogIn: false,
                     logInCredentials: nil,
                     gbfs: GBFS(stationStatus: "https://gbfs.citibikenyc.com/gbfs/en/station_status.json", stationInformation: "https://gbfs.citibikenyc.com/gbfs/en/station_information.json")
    ),
    "Bilbao": City(apiName: "bilbao",
                   formalName: "Bilbao",
                   latitude: 43.267427,
                   longitude: -2.937792,
                   apiUrl: "https://nextbike.net/maps/nextbike-official.json?city=532",
                   allowsLogIn: false,
                   logInCredentials: nil,
                   gbfs: nil
    ),
    "Madrid": City(apiName: "madrid",
                   formalName: "Madrid",
                   latitude: 40.419953,
                   longitude: -3.688479,
                   apiUrl: "https://openapi.emtmadrid.es/v1/transport/bicimad/stations/",
                   allowsLogIn: false,
                   logInCredentials: ApiPreLogIn(url: "https://openapi.emtmadrid.es/v1/mobilitylabs/user/login/", username: "javierdemartin@me.com", password: "zXF2AbQt7L6#", apiKey: "76eb9ed5-25b6-4e57-a905-71d4ac2ecdf2", clientId: "f64bb631-8b03-426d-a1e3-9939a571003a"),
                   gbfs: nil
    ),
//    "London": City(apiName: "london",
//                   formalName: "London",
//                   latitude: 51.507492,
//                   longitude: -0.127302,
//                   apiUrl: "https://api.tfl.gov.uk/BikePoint",
//                   allowsLogIn: false,
//                   logInCredentials: nil,
//                   gbfs: nil
//    )
]

enum AvailableCities: String {
    case newYork = "New York"
    case bilbao = "Bilbao"
    case madrid = "Madrid"
//    case london = "London"
}

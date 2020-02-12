//
//  BiciMad.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 07/02/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation

struct BiciMadOpenApiTokenResponse: Decodable {
    let data: [BiciMadApiTokenData]
}

struct BiciMadApiTokenData: Decodable {
    let accessToken: String
}

struct BiciMadRoot: Decodable {
    let data: [BiciMadStation]
}

struct BiciMadStation: BikeStation {
    var id: String

    var freeBikes: Int

    var stationName: String

    var latitude: Double

    var longitude: Double

    var geometry: BiciMadStationGeometry

    enum CodingKeys: String, CodingKey {
        case id
        case stationName = "name"
        case freeBikes = "dock_bikes"
        case latitude
        case longitude
        case geometry
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        id = (try "\(values.decode(Int.self, forKey: .id))")
        freeBikes = try values.decode(Int.self, forKey: .freeBikes)
        stationName = try values.decode(String.self, forKey: .stationName).replacingOccurrences(of: "\\d{1,}.", with: "", options: [.regularExpression])

        geometry = try values.decode(BiciMadStationGeometry.self, forKey: .geometry)

        latitude = geometry.coordinates[1]
        longitude = geometry.coordinates[0]
    }
}

struct BiciMadStationGeometry: Decodable {
    let coordinates: [Double]
}

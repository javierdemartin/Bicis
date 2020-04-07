//
//  BiciMad.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 07/02/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import CoreLocation

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
    var freeRacks: Int

    var stationName: String

    var latitude: Double

    var longitude: Double

    var geometry: BiciMadStationGeometry

    var availabilityArray: [Int]?
    var predictionArray: [Int]?

    var location: CLLocation {
        return CLLocation(latitude: self.latitude, longitude: self.longitude)
    }

    func distance(to location: CLLocation) -> CLLocationDistance {
        return location.distance(from: self.location)
    }

    var percentageOfFreeBikes: Double {
        return (Double(freeBikes) / Double(totalAvailableDocks)) * 100
    }

    var totalAvailableDocks: Int {
        return freeRacks + freeBikes
    }

    var rmse: Double? {

            guard let availability = availabilityArray else { return nil }
            guard let prediction = predictionArray else { return nil }

        let range = Double(max(availability.max()!, prediction.max()!))

            var rmseResult = 0.0

            for element in 0..<availability.count {
                rmseResult += pow(Double(prediction[element] - availability[element]), 2.0)
            }

            rmseResult = sqrt(1/Double(availability.count) * rmseResult)

            return (rmseResult/range * 100)
    }

    var inverseAccuracyRmse: Double? {
        guard rmse != nil else { return nil }

        return 100 - rmse!
    }

    enum CodingKeys: String, CodingKey {
        case id
        case stationName = "name"
        case freeBikes = "dock_bikes"
        case freeRacks = "free_bases"
        case latitude
        case longitude
        case geometry
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        id = (try "\(values.decode(Int.self, forKey: .id))")
        freeBikes = try values.decode(Int.self, forKey: .freeBikes)
        freeRacks = try values.decode(Int.self, forKey: .freeRacks)
        stationName = try values.decode(String.self, forKey: .stationName).replacingOccurrences(of: "\\d{1,}.", with: "", options: [.regularExpression])

        geometry = try values.decode(BiciMadStationGeometry.self, forKey: .geometry)

        latitude = geometry.coordinates[1]
        longitude = geometry.coordinates[0]
    }
}

struct BiciMadStationGeometry: Decodable {
    let coordinates: [Double]
}

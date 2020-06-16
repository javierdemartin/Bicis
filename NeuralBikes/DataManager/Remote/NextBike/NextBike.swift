//
//  Bilbao.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 05/02/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import CoreLocation

struct NextBikeRoot: Decodable {
    let countries: [NextBikeCities]
}

struct NextBikeCities: Decodable {
    let cities: [NextBikePlaces]
}

struct NextBikePlaces: Decodable {
    let places: [NextBikeStation]
}

struct NextBikeStation: BikeStation {

    var id: String
    var freeBikes: Int
    var freeRacks: Int
    var stationName: String
    var latitude: Double
    var longitude: Double

    var location: CLLocation {
        return CLLocation(latitude: self.latitude, longitude: self.longitude)
    }

    func distance(to location: CLLocation) -> CLLocationDistance {
        return location.distance(from: self.location)
    }

    var percentageOfFreeBikes: Double {
        return (Double(freeBikes) / Double(totalAvailableDocks)) * 100
    }

    var availabilityArray: [Int]?
    var predictionArray: [Int]?

    var totalAvailableDocks: Int {
        return freeRacks + freeBikes
    }

    var rmse: Double? {

        guard let availability = availabilityArray else { return nil }
        guard let prediction = predictionArray else { return nil }

        let range = Double(max(availability.max()!, prediction.max()!))

        if range == 0 {
            return nil
        }

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
        case id = "uid"
        case freeBikes = "bikes"
        case freeRacks = "free_racks"
        case stationName = "name"
        case latitude = "lat"
        case longitude = "lng"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        id = (try "\(values.decode(Int.self, forKey: .id))")

        freeBikes = try values.decode(Int.self, forKey: .freeBikes)
        freeRacks = try values.decode(Int.self, forKey: .freeRacks)
        stationName = try values.decode(String.self, forKey: .stationName).replacingOccurrences(of: "\\d{1,}.", with: "", options: [.regularExpression])
        latitude = try values.decode(Double.self, forKey: .latitude)
        longitude = try values.decode(Double.self, forKey: .longitude)
    }
    
    init(id: String, freeBikes: Int, freeDocks: Int, stationName: String, latitude: Double, longitude: Double) {
        self.id = id
        self.freeBikes = freeBikes
        self.freeRacks = freeDocks
        self.stationName = stationName
        self.latitude = latitude
        self.longitude = longitude
    }
}

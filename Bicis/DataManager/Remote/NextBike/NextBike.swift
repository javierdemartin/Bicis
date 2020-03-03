//
//  Bilbao.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 05/02/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation

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
    var stationName: String
    var latitude: Double
    var longitude: Double

    var availabilityArray: [Int]?
    var predictionArray: [Int]?

    var rmse: Double? {
        get {

            guard let availability = availabilityArray else { return nil }
            guard let prediction = predictionArray else { return nil }

            var maxValue = max(availability.max()!, prediction.max()!)

            var rmseResult = 0.0

            for element in 0..<availability.count {
                rmseResult += pow(Double(prediction[element] - availability[element]), 2.0)
            }

            rmseResult = sqrt(1/Double(availability.count) * rmseResult)

            return rmseResult
        }
    }

    enum CodingKeys: String, CodingKey {
        case id = "uid"
        case freeBikes = "bikes"
        case stationName = "name"
        case latitude = "lat"
        case longitude = "lng"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        id = (try "\(values.decode(Int.self, forKey: .id))")

        freeBikes = try values.decode(Int.self, forKey: .freeBikes)
        stationName = try values.decode(String.self, forKey: .stationName).replacingOccurrences(of: "\\d{1,}.", with: "", options: [.regularExpression])
        latitude = try values.decode(Double.self, forKey: .latitude)
        longitude = try values.decode(Double.self, forKey: .longitude)
    }
}

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
    var freeRacks: Int { get set }
    var stationName: String { get set }
    var latitude: Double { get set }
    var longitude: Double { get set }
    var percentageOfFreeBikes: Double { get }
    // Not parseable
    var totalAvailableDocks: Int { get }
    var availabilityArray: [Int]? { get set }
    var predictionArray: [Int]? { get set }
    var rmse: Double? { get }
    var inverseAccuracyRmse: Double? { get }
}

struct CitiBikesStation: BikeStation {
    var latitude: Double
    var longitude: Double
    var stationName: String
    var id: String
    var freeBikes: Int
    var freeRacks: Int

    var availabilityArray: [Int]?
    var predictionArray: [Int]?

    var totalAvailableDocks: Int {
        return freeRacks + freeBikes
    }

    var percentageOfFreeBikes: Double {
        return (Double(freeBikes) / Double(totalAvailableDocks)) * 100
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

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        id = (try "\(values.decode(Int.self, forKey: .id))")

        freeBikes = try values.decode(Int.self, forKey: .freeBikes)
        freeRacks = try values.decode(Int.self, forKey: .freeRacks)
        stationName = try values.decode(String.self, forKey: .stationName)
        latitude = try values.decode(Double.self, forKey: .latitude)
        longitude = try values.decode(Double.self, forKey: .longitude)
    }

    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case stationName = "stationName"
        case id
        case freeBikes = "availableBikes"
        case freeRacks = "availableDocks"
    }
}

struct CitiBikesRoot: Decodable {
    let stationBeanList: [CitiBikesStation]
}

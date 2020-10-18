//
//  SantanderBikesLondon.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 11/07/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import CoreLocation

struct SantanderBikesRoot: Decodable {
    let countries: [SantanderBikesStation]
}

struct SantanderBikeSAdditionalProperties: Decodable {
    
    var key: String
    var value: String
}

struct SantanderBikesStation: BikeStation {

    var id: String
    var freeBikes: Int
    var freeRacks: Int
    var stationName: String
    var latitude: Double
    var longitude: Double
    var additionalProperties: [SantanderBikeSAdditionalProperties]

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
        case id = "id"
        case freeBikes = "bikes"
        case freeRacks = "free_racks"
        case stationName = "commonName"
        case latitude = "lat"
        case longitude = "lon"
        case additionalProperties = "additionalProperties"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        id = (try "\(values.decode(String.self, forKey: .id))")

//        freeBikes = try values.decode(Int.self, forKey: .freeBikes)
//        freeRacks = try values.decode(Int.self, forKey: .freeRacks)
        freeBikes = 0
        freeRacks = 0
        stationName = try values.decode(String.self, forKey: .stationName)
        latitude = try values.decode(Double.self, forKey: .latitude)
        longitude = try values.decode(Double.self, forKey: .longitude)
        additionalProperties = try values.decode([SantanderBikeSAdditionalProperties].self, forKey: .additionalProperties)
        
        if let freeBikesParsed = additionalProperties.first(where: { $0.key == "NbBikes" }) {
            freeBikes = Int(freeBikesParsed.value) ?? 0
        }
        
        
        if let freeRacksParsed = additionalProperties.first(where: { $0.key == "NbEmptyDocks" }) {
            freeRacks = Int(freeRacksParsed.value) ?? 0
        }
        
//        if let freeBikes = additionalProperties.first(where: $0.k == "key") {
//
//        }
    }
    
    init(id: String, freeBikes: Int, freeDocks: Int, stationName: String, latitude: Double, longitude: Double, additionalProperties: [SantanderBikeSAdditionalProperties]) {
//    init(id: String, freeBikes: Int, freeDocks: Int, stationName: String, latitude: Double, longitude: Double, additionalProperties: [SantanderBikeSAdditionalProperties]) {
        self.id = id
        self.freeBikes = freeBikes
        self.freeRacks = freeDocks
        self.stationName = stationName
        self.latitude = latitude
        self.longitude = longitude
        self.additionalProperties = additionalProperties
    }
}
